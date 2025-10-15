data "aws_iam_policy" "task_exec" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_tasks_assume_condition" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [format("arn:aws:ecs:%s:%s:*", var.aws_region, data.aws_caller_identity.current.account_id)]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "github_runner_task_exec" {
  name = format("%s-github-runner-ecs-task-exec-%s-es1", var.short_name, var.env)

  assume_role_policy  = data.aws_iam_policy_document.ecs_tasks_assume.json
  managed_policy_arns = toset([data.aws_iam_policy.task_exec.arn])

  inline_policy {
    name = "CreateLogGroup"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "logs:CreateLogGroup"
          Resource = "*"
        }
      ]
    })
  }
}

locals {
  analytics_deployment_github_repo_iam_role_name = format("%s-analytics-deployment-github-repo-%s", local.project, var.env)
  analytics_deployment_github_repo_iam_role_arn  = format("arn:aws:iam::%s:role/%s", data.aws_caller_identity.current.account_id, local.analytics_deployment_github_repo_iam_role_name)

  public_catalog_deployment_github_repo_iam_role_name = format("%s-public-catalog-deployment-github-repo-%s", local.project, var.env)
  public_catalog_deployment_github_repo_iam_role_arn  = format("arn:aws:iam::%s:role/%s", data.aws_caller_identity.current.account_id, local.public_catalog_deployment_github_repo_iam_role_name)
}

resource "aws_iam_role" "github_runner_task" {
  name = format("%s-github-runner-task-%s-es1", var.short_name, var.env)

  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_condition.json

  inline_policy {
    name = "KubeConfigPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "eks:DescribeCluster"
          Resource = "*"
        }
      ]
    })
  }

  inline_policy {
    name = "SecretsAccessPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "secretsmanager:GetSecretValue"
          Resource = "*"
        }
      ]
    })
  }

  inline_policy {
    name = "ReadImagesPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage"
          ]
          Resource = "*"
        }
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = local.deploy_be_refactor_infra ? [1] : []

    content {
      name = "KafkaTopics"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "kafka-cluster:Connect",
              "kafka-cluster:CreateTopic",
              "kafka-cluster:DeleteTopic",
              "kafka-cluster:DescribeCluster",
              "kafka-cluster:DescribeTopic",
              "kafka-cluster:DescribeTopicDynamicConfiguration"
            ]
            Resource = [
              aws_msk_cluster.platform_events[0].arn,
              "${local.msk_topic_iam_prefix}/event-store.*",
              "${local.msk_topic_iam_prefix}/outbound.*",
              "${local.msk_topic_iam_prefix}/*_authorization-server.generated-jwt",
            ]
          }
        ]
      })
    }
  }

  inline_policy {
    name = "AssumeRolePolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "sts:AssumeRole",
            "sts:TagSession"
          ]
          # These locals are necessary otherwise referencing the deployment role resources would cause a dependency cicle 
          Resource = [
            local.analytics_deployment_github_repo_iam_role_arn,
            local.public_catalog_deployment_github_repo_iam_role_arn
          ]
        }
      ]
    })
  }
}

resource "aws_ecs_cluster" "github_runners" {
  name = format("%s-github-runners-%s", var.short_name, var.env)

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "fargate" {
  cluster_name = aws_ecs_cluster.github_runners.name

  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_task_definition" "github_runner" {
  family = format("%s-github-runner-%s", var.short_name, var.env)

  cpu                = var.github_runners_cpu
  memory             = var.github_runners_memory
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.github_runner_task_exec.arn
  task_role_arn      = aws_iam_role.github_runner_task.arn

  container_definitions = jsonencode([
    {
      name      = "github-runner"
      cpu       = var.github_runners_cpu
      memory    = var.github_runners_memory
      essential = true
      image     = var.github_runners_image_uri

      portMappngs = [
        {
          containerPort = 443
          hostPort      = 443
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = "/aws/ecs"
          awslogs-stream-prefix = "github-runners"
          awslogs-create-group  = "true"
        }
      }
    }
  ])
}

resource "aws_security_group" "github_runners" {
  name        = format("%s-github-runners-%s", var.short_name, var.env)
  description = "SG for Github runners"

  vpc_id = module.vpc.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_iam_role" "github_qa_runner_task" {
  count = var.env == "dev" || var.env == "qa" || var.env == "vapt" ? 1 : 0

  name = format("%s-github-qa-runner-task-%s-es1", var.short_name, var.env)

  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_condition.json

  inline_policy {
    name = "KubeConfigPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "eks:DescribeCluster"
          Resource = "*"
        }
      ]
    })
  }

  inline_policy {
    name = "SecretsAccessPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "secretsmanager:GetSecretValue"
          Resource = "*"
        }
      ]
    })
  }

  inline_policy {
    name = "BucketAccessPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            module.data_preparation_bucket[0].s3_bucket_arn,
            "${module.data_preparation_bucket[0].s3_bucket_arn}/*"
          ]
        }
      ]
    })
  }

  inline_policy {
    name = "SignSessionTokens"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "kms:Sign",
            "kms:Verify"
          ]
          Resource = aws_kms_key.interop.arn
        }
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = local.deploy_be_refactor_infra ? [1] : []

    content {
      name = "KafkaTopics"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "kafka-cluster:Connect",
              "kafka-cluster:CreateTopic",
              "kafka-cluster:DeleteTopic",
              "kafka-cluster:DescribeCluster",
              "kafka-cluster:DescribeTopic",
              "kafka-cluster:DescribeTopicDynamicConfiguration"
            ]
            Resource = [
              aws_msk_cluster.platform_events[0].arn,
              "${local.msk_topic_iam_prefix}/*",
            ]
          },
          {
            Effect = "Deny"
            Action = [
              "kafka-cluster:CreateTopic",
              "kafka-cluster:DeleteTopic",
            ]
            Resource = "${local.msk_topic_iam_prefix}/__*"
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = local.deploy_be_refactor_infra ? [1] : []

    content {
      name = "PurgeAuthServerDynamoDB"

      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "dynamodb:BatchWriteItem",
              "dynamodb:DescribeTable",
              "dynamodb:Scan",
            ]
            Resource = [
              aws_dynamodb_table.platform_states[0].arn,
              aws_dynamodb_table.token_generation_states[0].arn
            ]
          }
        ]
      })
    }
  }
}

resource "aws_ecs_task_definition" "github_qa_runner" {
  count = var.env == "dev" || var.env == "qa" || var.env == "vapt" ? 1 : 0

  family = format("%s-github-qa-runner-%s", var.short_name, var.env)

  cpu                = 4096
  memory             = 8192
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.github_runner_task_exec.arn
  task_role_arn      = aws_iam_role.github_qa_runner_task[0].arn

  container_definitions = jsonencode([
    {
      name      = "github-qa-runner"
      cpu       = 4096
      memory    = 8192
      essential = true
      image     = "ghcr.io/pagopa/interop-qa-runner:v1.21.1"

      portMappngs = [
        {
          containerPort = 443
          hostPort      = 443
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.aws_region
          awslogs-group         = "/aws/ecs"
          awslogs-stream-prefix = "github-qa-runners"
          awslogs-create-group  = "true"
        }
      }
    }
  ])
}
