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

# - Needed by QuickSight until migration at aws provider version 6.0.0.
#   Version 6.0.0 will introduce region argument in aws_quicksight_account_subscription resource.
provider "aws" {
  region = var.quicksight_identity_center_region
  alias  = "identity_center_region"

  default_tags {
    tags = var.tags
  }
}

data "aws_caller_identity" "current" {}

locals {
  project                 = "interop"
  deploy_redshift_cluster = var.env == "dev" || var.env == "prod"
  terraform_state         = "analytics-quicksight"

  # Deploy SPICE dataset refresh schedule lambda
  deploy_datasets_schedule_lambda = (
    local.deploy_redshift_cluster && var.quicksight_datasets_schedule_lambda != null
  )
}
