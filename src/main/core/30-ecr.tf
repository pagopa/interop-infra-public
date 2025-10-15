locals {
  repository_names = [
    "interop-be-agreement-email-sender",
    "interop-be-agreement-management",
    "interop-be-agreement-outbound-writer",
    "interop-be-agreement-platformstate-writer",
    "interop-be-agreement-process",
    "interop-be-agreement-readmodel-writer",
    "interop-be-agreement-readmodel-writer-sql",
    "interop-be-anac-certified-attributes-importer",
    "interop-be-api-gateway",
    "interop-be-application-audit-fallback",
    "interop-be-attribute-registry-management",
    "interop-be-attribute-registry-process",
    "interop-be-attribute-registry-readmodel-writer",
    "interop-be-attribute-registry-readmodel-writer-sql",
    "interop-be-attributes-loader",
    "interop-be-authorization-management",
    "interop-be-authorization-platformstate-writer",
    "interop-be-authorization-process",
    "interop-be-authorization-server",
    "interop-be-authorization-updater",
    "interop-be-backend-for-frontend",
    "interop-be-catalog-management",
    "interop-be-catalog-outbound-writer",
    "interop-be-catalog-platformstate-writer",
    "interop-be-catalog-process",
    "interop-be-catalog-readmodel-writer",
    "interop-be-catalog-readmodel-writer-sql",
    "interop-be-certified-email-sender",
    "interop-be-certified-mail-sender",
    "interop-be-client-purpose-updater",
    "interop-be-client-readmodel-writer",
    "interop-be-client-readmodel-writer-sql",
    "interop-be-compute-agreements-consumer",
    "interop-be-dashboard-metrics-report-generator",
    "interop-be-datalake-data-export",
    "interop-be-datalake-interface-exporter",
    "interop-be-delegation-items-archiver",
    "interop-be-delegation-outbound-writer",
    "interop-be-delegation-process",
    "interop-be-delegation-readmodel-writer",
    "interop-be-delegation-readmodel-writer-sql",
    "interop-be-dtd-catalog-exporter",
    "interop-be-dtd-catalog-total-load-exporter",
    "interop-be-dtd-metrics",
    "interop-be-email-sender",
    "interop-be-email-notification-dispatcher",
    "interop-be-eservice-descriptors-archiver",
    "interop-be-eservice-template-instances-updater",
    "interop-be-eservice-template-outbound-writer",
    "interop-be-eservice-template-process",
    "interop-be-eservice-template-readmodel-writer",
    "interop-be-eservice-template-readmodel-writer-sql",
    "interop-be-eservices-monitoring-exporter",
    "interop-be-events-signer",
    "interop-be-in-app-notification-dispatcher",
    "interop-be-in-app-notification-manager",
    "interop-be-ipa-certified-attributes-importer",
    "interop-be-ivass-certified-attributes-importer",
    "interop-be-key-readmodel-writer",
    "interop-be-key-readmodel-writer-sql",
    "interop-be-kpi-domains-readmodel-checker",
    "interop-be-m2m-event-dispatcher",
    "interop-be-m2m-event-manager",
    "interop-be-m2m-gateway",
    "interop-be-metrics-report-generator",
    "interop-be-notification-config-process",
    "interop-be-notification-config-readmodel-writer-sql",
    "interop-be-notification-email-sender",
    "interop-be-notification-tenant-lifecycle-consumer",
    "interop-be-notification-user-lifecycle-consumer",
    "interop-be-notifier",
    "interop-be-notifier-seeder",
    "interop-be-one-trust-notices",
    "interop-be-padigitale-report-generator",
    "interop-be-party-management",
    "interop-be-party-mock-registry",
    "interop-be-party-process",
    "interop-be-party-registry-proxy",
    "interop-be-pn-consumers",
    "interop-be-privacy-notices-updater",
    "interop-be-producer-key-events-writer",
    "interop-be-producer-key-readmodel-writer",
    "interop-be-producer-key-readmodel-writer-sql",
    "interop-be-producer-keychain-readmodel-writer",
    "interop-be-producer-keychain-readmodel-writer-sql",
    "interop-be-purpose-management",
    "interop-be-purpose-outbound-writer",
    "interop-be-purpose-platformstate-writer",
    "interop-be-purpose-process",
    "interop-be-purpose-readmodel-writer",
    "interop-be-purpose-readmodel-writer-sql",
    "interop-be-purpose-template-process",
    "interop-be-purpose-template-readmodel-writer-sql",
    "interop-be-purposes-archiver",
    "interop-be-readmodel-checker",
    "interop-be-selfcare-client-users-updater",
    "interop-be-selfcare-onboarding-consumer",
    "interop-be-tenant-management",
    "interop-be-tenant-outbound-writer",
    "interop-be-tenant-process",
    "interop-be-tenant-readmodel-writer",
    "interop-be-tenant-readmodel-writer-sql",
    "interop-be-tenants-attributes-checker",
    "interop-be-tenants-cert-attr-updater",
    "interop-be-token-details-persister",
    "interop-be-token-generation-readmodel-checker",
    "interop-debezium-postgresql",
    "interop-frontend"
  ]
}

resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  count = var.env == "dev" ? 1 : 0

  upstream_registry_url = "public.ecr.aws"
  ecr_repository_prefix = "ecr-public"
}

resource "aws_ecr_repository" "app" {
  for_each = toset(local.repository_names)

  image_tag_mutability = var.env == "test" || var.env == "prod" ? "IMMUTABLE" : "MUTABLE"
  name                 = each.key
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = { for repo in aws_ecr_repository.app : repo.name => repo if var.env == "dev" }

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

# TODO: restrict to only GH ECR role once new CI is ready
resource "aws_ecr_repository_policy" "dev_cross_account" {
  for_each = { for repo in aws_ecr_repository.app : repo.name => repo if var.env == "dev" }

  repository = each.value.name

  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid    = "QA Pull",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::755649575658:root"
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      },
      {
        Sid    = "VAPT Pull",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::565393043798:root"
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      },
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
        Sid    = "Att Pull",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::533267098416:root"
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
      },
      {
        Sid    = "GitubEcrPullFromTest"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::895646477129:role/interop-github-ecr-test",
            "arn:aws:iam::697818730278:role/interop-github-ecr-prod"
          ]
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      },
      {
        Sid    = "GithubEcrRetagFromTest"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::895646477129:role/interop-github-ecr-test",
            "arn:aws:iam::697818730278:role/interop-github-ecr-prod"
          ]
        },
        Action = [
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "uat_cross_account" {
  for_each = { for repo in aws_ecr_repository.app : repo.name => repo if var.env == "test" }

  repository = each.value.name

  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid    = "GitubEcrPullFromProd"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::697818730278:role/interop-github-ecr-prod"
        },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
      },
      {
        Sid    = "GithubEcrRetagFromProd"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::697818730278:role/interop-github-ecr-prod"
        },
        Action = [
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  })
}
