locals {
  deployment_github_repo_iam_role_name = format("%s-analytics-deployment-github-repo-%s", local.project, var.env)
}

data "aws_iam_policy_document" "deployment_github_repo_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [format("repo:%s:*", var.deployment_repo_name)]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.github_runner_task.arn]
    }
  }
}

resource "aws_iam_role" "deployment_github_repo" {
  name = local.deployment_github_repo_iam_role_name

  assume_role_policy  = data.aws_iam_policy_document.deployment_github_repo_assume.json
  managed_policy_arns = [aws_iam_policy.deployment_github_repo.arn]
}

resource "aws_iam_policy" "deployment_github_repo" {
  name = "AnalyticsDeploymentGithubRepo"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          format("%s/*/interop-analytics-deployment/monitoring.tfstate", data.aws_s3_bucket.terraform_states.arn),
          format("%s/*/interop-analytics-deployment/secrets.tfstate", data.aws_s3_bucket.terraform_states.arn)
        ]
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [data.aws_s3_bucket.terraform_states.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = [data.aws_dynamodb_table.terraform_lock.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/EKSClusterName" = data.aws_eks_cluster.core.name,
            "aws:ResourceTag/TerraformState" = local.terraform_state
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:ListTagsForResource"
        ]
        Resource = format("arn:aws:cloudwatch:%s:%s:alarm:*", var.aws_region, data.aws_caller_identity.current.account_id)
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm"
        ]
        Resource = format("arn:aws:cloudwatch:%s:%s:alarm:*", var.aws_region, data.aws_caller_identity.current.account_id)
        Condition = {
          StringEqualsIfExists = {
            "aws:ResourceTag/Source" = format("https://github.com/%s", var.deployment_repo_name)
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:TagResource"
        ]
        Resource = format("arn:aws:cloudwatch:%s:%s:alarm:*", var.aws_region, data.aws_caller_identity.current.account_id)
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Source" = format("https://github.com/%s", var.deployment_repo_name),
          },
          StringEqualsIfExists = {
            "aws:RequestTag/Source" = format("https://github.com/%s", var.deployment_repo_name)
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:UntagResource"
        ]
        Resource = format("arn:aws:cloudwatch:%s:%s:alarm:*", var.aws_region, data.aws_caller_identity.current.account_id)
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Source" = format("https://github.com/%s", var.deployment_repo_name),
          },
          StringNotEqualsIfExists = {
            "aws:RequestTagKeys" = ["Source"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DeleteAlarms"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Source" = format("https://github.com/%s", var.deployment_repo_name)
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetDashboard",
          "cloudwatch:PutDashboard",
          "cloudwatch:DeleteDashboards"
        ]
        Resource = format("arn:aws:cloudwatch::%s:dashboard/k8s-*", data.aws_caller_identity.current.account_id)
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeMetricFilters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:ListTopics"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "s3_reprocess_github_repo_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [format("repo:%s:*", var.s3_reprocess_repo_name)]
    }
  }
}

resource "aws_iam_role" "s3_reprocess_github_repo" {
  name = format("%s-analytics-s3-reprocess-%s-es1", local.project, var.env)

  assume_role_policy  = data.aws_iam_policy_document.s3_reprocess_github_repo_assume.json
  managed_policy_arns = [aws_iam_policy.s3_reprocess_github_repo.arn]
}

resource "aws_iam_policy" "s3_reprocess_github_repo" {
  name = "AnalyticsS3ReprocessGithubRepoPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = "s3:ListBucket"
          Resource = [
            data.aws_s3_bucket.jwt_audit_source.arn,
            data.aws_s3_bucket.alb_logs_source.arn
          ]
        }
      ],
      local.deploy_all_data_ingestion_resources ? [
        {
          Effect = "Allow"
          Action = [
            "sqs:SendMessage"
          ]
          Resource = [
            aws_sqs_queue.jwt_audit[0].arn,
            aws_sqs_queue.alb_logs[0].arn
          ]
        }
      ] : []
    )
  })
}
