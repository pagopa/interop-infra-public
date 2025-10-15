data "aws_vpc" "core" {
  id = var.vpc_id
}

data "aws_subnets" "analytics" {
  filter {
    name   = "subnet-id"
    values = var.analytics_subnet_ids
  }
}

data "aws_security_group" "vpn_clients" {
  id = var.vpn_clients_security_group_id
}

data "aws_eks_cluster" "core" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "core" {
  name = var.eks_cluster_name
}

data "aws_iam_openid_connect_provider" "core_eks" {
  url = data.aws_eks_cluster.core.identity[0].oidc[0].issuer
}

data "aws_security_group" "core_eks_cluster_node" {
  id = var.eks_cluster_node_security_group_id
}

data "aws_dynamodb_table" "terraform_lock" {
  name     = "terraform-lock"
  provider = aws.ec1
}

data "aws_s3_bucket" "terraform_states" {
  bucket   = format("terraform-backend-%s", data.aws_caller_identity.current.account_id)
  provider = aws.ec1
}

data "aws_s3_bucket" "jwt_audit_source" {
  bucket = var.jwt_details_bucket_name
}

data "aws_s3_bucket" "alb_logs_source" {
  bucket = var.alb_logs_bucket_name
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_role" "github_runner_task" {
  name = var.github_runner_task_role_name
}

data "aws_msk_cluster" "platform_events" {
  cluster_name = var.msk_cluster_name
}

data "aws_iam_role" "application_audit_producers" {
  for_each = toset(var.application_audit_producers_irsa_list)

  name = each.value
}

data "aws_sns_topic" "jwt_details_new_s3_object" {
  name = var.jwt_details_s3_events_topic_name
}

data "aws_redshift_cluster" "cross_account" {
  count = local.deploy_redshift_cross_account ? 1 : 0

  provider           = aws.redshift_describe_clusters
  cluster_identifier = var.redshift_cross_account_cluster.cluster_id
}

data "aws_secretsmanager_secret" "redshift_master_cross_account" {
  count = local.deploy_redshift_cross_account ? 1 : 0

  provider = aws.redshift_get_master_secret
  name     = var.redshift_cross_account_cluster.master_secret_id
}

data "aws_iam_policy" "glue_service_role" {
  count = local.deploy_spark_etl_jobs ? 1 : 0

  name = "AWSGlueServiceRole"
}
