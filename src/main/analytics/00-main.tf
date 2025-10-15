terraform {
  required_version = "~> 1.8.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  region = "eu-central-1"
  alias  = "ec1"

  default_tags {
    tags = var.tags
  }
}

# Needed to assume the IAM role to describe the Redshift clusters in case of cross-account access
provider "aws" {
  region = var.aws_region
  alias  = "redshift_describe_clusters"

  assume_role {
    role_arn = var.redshift_cross_account_cluster != null ? format("arn:aws:iam::%s:role/%s", var.redshift_cross_account_cluster.aws_account_id, var.redshift_describe_clusters_role_name) : null
  }
}

# Needed to assume the IAM role to get the Redshift's master secret in case of cross-account access
provider "aws" {
  region = var.aws_region
  alias  = "redshift_get_master_secret"

  assume_role {
    role_arn = var.redshift_cross_account_cluster != null ? format("arn:aws:iam::%s:role/%s", var.redshift_cross_account_cluster.aws_account_id, var.redshift_get_master_secret_role_name) : null
  }
}

# - Needed by QuickSight until migration at aws provider version 6.0.0.
#   Version 6.0.0 will introduce region argument in aws_quicksight_account_subscription resource.
# TODO: Remove after apply to prod. It is still needed for destruction of QuickSight subscription
provider "aws" {
  region = "eu-west-1"
  alias  = "identity_center_region"

  default_tags {
    tags = var.tags
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.core.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.core.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.core.token
}

data "aws_caller_identity" "current" {}

data "aws_iam_role" "github_iac" {
  name = "GitHubActionIACRole"
}

data "aws_iam_role" "sso_admin" {
  name = var.sso_admin_role_name
}

locals {
  project         = "interop"
  terraform_state = "analytics"

  deploy_redshift_cluster                 = var.env == "dev" || var.env == "prod"
  deploy_all_data_ingestion_resources     = var.env == "dev" || var.env == "qa" || var.env == "prod"   # This local manages the deployment of the resources related to all of the ingestion flows: jwt audit, alb-logs, application audit, domains
  deploy_only_application_audit_resources = var.env == "vapt" || var.env == "test" || var.env == "att" # This local manages the deployment of the resources related to the application audit ingestion flow only
  deploy_redshift_cross_account           = var.env == "qa"
  deploy_uptime_cost_optimization         = local.deploy_redshift_cluster
  deploy_spark_etl_jobs                   = var.env == "dev" || var.env == "prod"

  # Deploy Materialized views refresh lambda
  deploy_mv_refresh_lambda = (
    local.deploy_redshift_cluster && var.redshift_materialized_views_refresher_lambda != null
  )
}
