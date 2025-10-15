# currently there isn't a native data source implemented for this resource
data "external" "gh_source_credentials" {
  count = local.deploy_codebuild_github_ci_runners ? 1 : 0

  program = ["bash", "-c",
    "aws codebuild list-source-credentials --output json | jq '.sourceCredentialsInfos | map(select(.serverType == \"GITHUB\")) | .[0] // {}'"
  ]
}

locals {
  configured_gh_source_credentials = try(length(data.external.gh_source_credentials[0].result) > 0, false)
  # format: org-name/repo-name
  gh_ci_runners_repos = local.deploy_codebuild_github_ci_runners && local.configured_gh_source_credentials ? [
    "pagopa/interop-be-monorepo",
  ] : []
}

resource "aws_cloudwatch_log_group" "codebuild_gh_ci_runners" {
  for_each = toset(local.gh_ci_runners_repos)

  name = format("/aws/codebuild/github-runners/%s", each.value)

  retention_in_days = var.env == "prod" ? 365 : 90
  skip_destroy      = true
}

resource "aws_iam_policy" "codebuild_gh_ci_runners" {
  count = local.deploy_codebuild_github_ci_runners ? 1 : 0

  name = "InteropCodeBuildGithubCIRunners"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = formatlist("%s:*", [for k, v in aws_cloudwatch_log_group.codebuild_gh_ci_runners : v.arn])
      },
      {
        Sid    = "CodeBuildReportGroups"
        Effect = "Allow"
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ]
        Resource = "*"
      },
      {
        Sid    = "SystemsManager"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECR"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetAuthorizationToken",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "codebuild_gh_ci_runners" {
  count = local.deploy_codebuild_github_ci_runners ? 1 : 0

  name = format("%s-codebuild-github-ci-runners-%s", local.project, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [aws_iam_policy.codebuild_gh_ci_runners[0].arn]
}

resource "aws_codebuild_project" "gh_ci_runners" {
  for_each = toset(local.gh_ci_runners_repos)

  name         = format("%s-github-runners-%s", replace(each.value, "/", "-"), var.env)
  service_role = aws_iam_role.codebuild_gh_ci_runners[0].arn

  concurrent_build_limit = 200
  build_timeout          = 120 # minutes
  queued_timeout         = 15  # minutes

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    privileged_mode = true
  }

  source {
    type            = "GITHUB"
    location        = format("https://github.com/%s.git", each.value)
    git_clone_depth = 1
  }

  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = aws_cloudwatch_log_group.codebuild_gh_ci_runners[each.value].name
    }
  }
}

resource "aws_codebuild_webhook" "gh_ci_runners" {
  for_each = toset(local.gh_ci_runners_repos)

  project_name = aws_codebuild_project.gh_ci_runners[each.value].name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "WORKFLOW_JOB_QUEUED"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "gh_ci_runners_failed_builds" {
  for_each = aws_codebuild_project.gh_ci_runners

  alarm_name = format("codebuild-%s-failed-builds", each.key)

  alarm_actions = [aws_sns_topic.platform_alarms.arn]

  namespace   = "AWS/CodeBuild"
  metric_name = "FailedBuilds"

  dimensions = {
    ProjectName = each.value.name
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  threshold           = 1
  period              = 60 # 1 minute
  evaluation_periods  = 5
  datapoints_to_alarm = 1
}

resource "aws_cloudwatch_metric_alarm" "gh_ci_runners_concurrent_builds" {
  for_each = aws_codebuild_project.gh_ci_runners

  alarm_name = format("codebuild-%s-concurrent-builds", each.key)

  alarm_actions = [aws_sns_topic.platform_alarms.arn]

  metric_query {
    id          = "e1"
    label       = "Usage Percentage"
    expression  = "(m1/${each.value.concurrent_build_limit}) * 100"
    return_data = true
  }

  metric_query {
    id          = "m1"
    label       = "Builds"
    return_data = false

    metric {
      stat   = "Sum"
      period = 60 # 1 minute

      namespace   = "AWS/CodeBuild"
      metric_name = "Builds"

      dimensions = {
        ProjectName = each.value.name
      }
    }
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  threshold           = 70
  evaluation_periods  = 5
  datapoints_to_alarm = 1
}
