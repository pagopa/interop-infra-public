locals {
  repository_names = [
    "interop-be-jwt-audit-analytics-writer",
    "interop-be-domains-analytics-writer",
    "interop-be-alb-logs-analytics-writer",
    "interop-be-application-audit-archiver",
    "interop-be-application-audit-analytics-writer"
  ]
}

resource "aws_ecr_repository" "app" {
  for_each = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? toset(local.repository_names) : []

  image_tag_mutability = var.env == "test" || var.env == "prod" ? "IMMUTABLE" : "MUTABLE"
  name                 = each.key
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? { for repo in aws_ecr_repository.app : repo.name => repo if var.env == "dev" } : {}

  repository = each.value.name
  policy     = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Delete untagged images",
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": 1
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}

resource "aws_ecr_repository_policy" "dev_cross_account" {
  for_each = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? { for repo in aws_ecr_repository.app : repo.name => repo if var.env == "dev" } : {}

  repository = each.value.name

  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid    = "Test Pull",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::895646477129:root"
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      },
      {
        Sid    = "Prod Pull",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::697818730278:root"
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      }
    ]
  })
}