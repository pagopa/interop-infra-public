variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "tags" {
  type = map(any)
  default = {
    CreatedBy = "Terraform"
  }
}

variable "sso_admin_role_name" {
  type        = string
  description = "Name of the SSO admin role"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to use"
}

variable "vpc_id" {
  type        = string
  description = "ID of the interop VPC"
}

variable "analytics_subnet_ids" {
  type        = list(string)
  description = "IDs of the analytics subnets"
}

variable "vpn_clients_security_group_id" {
  type        = string
  description = "ID of the VPN clients SG"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster accessing the analytics cluster"
}

variable "eks_cluster_node_security_group_id" {
  type        = string
  description = "ID of EKS cluster node SG"
}

variable "redshift_master_username" {
  type        = string
  description = "Master username of the Redshift database"
  default     = "root"
}

variable "redshift_cluster_nodes_number" {
  type        = number
  description = "Number of nodes for the Redshift cluster"
}

variable "redshift_cluster_nodes_type" {
  type        = string
  description = "Type of the nodes for the Redshift cluster"
}

variable "redshift_cluster_port" {
  type        = string
  description = "Port on which the Redshift cluster listens for incoming traffic"
  default     = "5439"
}

variable "redshift_databases_to_create" {
  type        = list(string)
  description = "List of databases to create in the Redshift cluster"
  default     = []
}

variable "redshift_enable_cross_account_access_account_id" {
  type        = string
  description = "ID of the account for which enabling cross-account access to the Redshift cluster"
  default     = null
}

variable "redshift_describe_clusters_role_name" {
  type        = string
  description = "Name of the IAM role to assume to describe the Redshift clusters (in another account) in case of cross-account access"
  default     = null
}

variable "redshift_get_master_secret_role_name" {
  type        = string
  description = "Name of the IAM role to assume to retrieve the Redshift's master secret and its related secret version (in another account) in case of cross-account access"
  default     = null
}

variable "redshift_cross_account_cluster" {
  type = object({
    aws_account_id   = string
    aws_account_env  = string
    cluster_id       = string
    master_secret_id = string
    database_name    = string
  })
  description = "Redshift cluster to use in case of cross-account access"
  default     = null
}

variable "jwt_details_bucket_name" {
  type        = string
  description = "Name of the S3 Bucket containing the generated jwt to be ingested in Redshift"
}

variable "jwt_details_s3_events_topic_name" {
  type        = string
  description = "Name of the SNS topic that multicast 'new object on jwt_detail_bucket' events"
}

variable "alb_logs_bucket_name" {
  type        = string
  description = "Name of the S3 Bucket containing ALB logs"
}

variable "tracing_aws_account_id" {
  type        = string
  description = "ID of the Tracing AWS account"
  default     = null
}

variable "tracing_vpc_id" {
  type        = string
  description = "ID of the VPC in the Tracing AWS account"
  default     = null
}

variable "analytics_qa_account_id" {
  type        = string
  description = "ID of Interop qa AWS account"
  default     = null
}

variable "analytics_qa_vpc_id" {
  type        = string
  description = "ID of the VPC in the Interop qa AWS account"
  default     = null
}

variable "analytics_k8s_namespace" {
  description = "Kubernetes namespace for the Analytics project"
  type        = string
}

variable "deployment_repo_name" {
  description = "Github repository name containing deployment automation"
  type        = string
}

variable "s3_reprocess_repo_name" {
  description = "Github repository name containing S3 reprocess script"
  type        = string
}

variable "github_runner_task_role_name" {
  description = "Name of the IAM role which is assumed by ECS tasks and allows to perform actions on the EKS cluster"
  type        = string
}

variable "msk_cluster_name" {
  description = "Name of the MSK cluster"
  type        = string
}

variable "msk_monitoring_app_audit_max_offset_lag_threshold" {
  description = "Threshold of the MaxOffsetLag alarm for the application audit MSK topic"
  type        = number
}

variable "msk_monitoring_app_audit_evaluation_periods" {
  description = "Evaluation periods of the MaxOffsetLag alarm for the application audit MSK topic"
  type        = number
}

variable "msk_monitoring_app_audit_period_seconds" {
  description = "Period in seconds of the MaxOffsetLag alarm for the application audit MSK topic"
  type        = number
}

variable "application_audit_producers_irsa_list" {
  description = "Names of the IRSA producers for application audit"
  type        = list(string)
  default     = []
}

variable "redshift_materialized_views_refresher_lambda" {
  description = <<-EOT
    Information about the lambda to use for materialized views refreshing.
      - zip_url: The URL of the release artifact from repository https://github.com/pagopa/interop-infra-lambdas
      - zip_sha256_hex: the sha256 checksum of the code archive, coded as hexadecimal string
  EOT
  type = object({
    zip_url        = string
    zip_sha256_hex = string
  })
}
