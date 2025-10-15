aws_region = "eu-south-1"
env        = "dev"
azs        = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]

tags = {
  CreatedBy   = "Terraform"
  Environment = "dev"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-infra"
}

sso_admin_role_name = ""

vpc_id               = "vpc-0df5f0ee96b0824c7"
analytics_subnet_ids = ["subnet-0f7445d4c56f10f3b", "subnet-0946493be6a7d2fbd", "subnet-05537a9801f26457c"]

vpn_clients_security_group_id = ""

eks_cluster_name                   = "interop-eks-cluster-dev"
eks_cluster_node_security_group_id = ""

redshift_cluster_nodes_number = 2
redshift_cluster_nodes_type   = "ra3.xlplus"

redshift_databases_to_create                    = ["interop_dev", "interop_qa"]
redshift_enable_cross_account_access_account_id = ""

jwt_details_bucket_name = "interop-generated-jwt-details-dev-es1"
alb_logs_bucket_name    = "interop-alb-logs-dev-es1"

jwt_details_s3_events_topic_name = "interop-jwt-details-new-s3-object-dev"

tracing_aws_account_id = ""
tracing_vpc_id         = ""

analytics_qa_account_id = ""
analytics_qa_vpc_id     = ""

analytics_k8s_namespace = "dev-analytics"

deployment_repo_name = ""

s3_reprocess_repo_name = ""

github_runner_task_role_name = "interop-github-runner-task-dev-es1"

msk_cluster_name = "interop-platform-events-dev"

msk_monitoring_app_audit_max_offset_lag_threshold = 500
msk_monitoring_app_audit_evaluation_periods       = 5
msk_monitoring_app_audit_period_seconds           = 60

application_audit_producers_irsa_list = [
  "interop-be-agreement-process-dev-es1",
  "interop-be-api-gateway-dev-es1",
  "interop-be-authorization-server-dev-es1",
  "interop-be-backend-for-frontend-dev-es1",
  "interop-be-catalog-process-dev-es1",
  "interop-be-delegation-process-dev-es1",
  "interop-be-m2m-gateway-dev-es1",
  "interop-be-purpose-process-dev-es1",
  "interop-be-tenant-process-dev-es1"
]


redshift_materialized_views_refresher_lambda = {
  zip_url        = "https://github.com/pagopa/interop-infra-lambdas/releases/download/v1.1.0/analytics-refresh-mv.zip"
  zip_sha256_hex = "260f6a724dfb245474b4b49b134bfc987608cff481aa5bddc391c34103c8e907"
}
