terraform {
  required_version = "~> 1.8.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }

  # avoid drift between VPC module and K8s tags applied only for some specific subnets
  ignore_tags {
    keys = ["kubernetes.io/role/elb", "kubernetes.io/role/internal-elb"]
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"

  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  region = var.env == "vapt" ? "eu-south-1" : "eu-central-1"
  alias  = "tf_backend"

  default_tags {
    tags = var.tags
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_role" "sso_admin" {
  name = var.sso_admin_role_name
}

locals {
  project                            = "interop"
  deploy_be_refactor_infra           = true # TODO: refactor 'count' that uses this local
  deploy_new_bff_apigw               = true # TODO: refactor 'count' that uses this local
  deploy_auth_server_refactor        = local.deploy_be_refactor_infra
  on_call_env                        = var.env == "dev" || var.env == "prod" # DEV is used for testing
  terraform_state                    = "core"
  deploy_read_model_refactor         = var.env == "dev" || var.env == "qa" || var.env == "vapt" || var.env == "test" || var.env == "att" || var.env == "prod"
  deployment_repo_v2_active          = var.env == "dev" || var.env == "qa" || var.env == "vapt" || var.env == "test" || var.env == "att" || var.env == "prod"
  deploy_interop_api_v2              = var.env == "dev" || var.env == "qa" || var.env == "vapt" || var.env == "test" || var.env == "att" || var.env == "prod"
  deploy_codebuild_github_ci_runners = var.env == "dev"
  deploy_eks_mng_ci_gh_runners       = false
  deploy_keda                     = var.env == "dev" || var.env == "qa"
  deploy_uptime_cost_optimization = var.env == "dev" || var.env == "qa"
  deploy_anac_sftp                = var.env == "dev" || var.env == "test" || var.env == "att" || var.env == "prod"
}
