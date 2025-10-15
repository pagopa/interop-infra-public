aws_region = "eu-south-1"
env        = "att"
azs        = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]

tags = {
  CreatedBy   = "Terraform"
  Environment = "att"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-infra"
}

sso_admin_role_name = "AWSReservedSSO_FullAdmin_b3727887a6d00b51"

vpc_id               = "vpc-04abd3bf4c51ec473"
analytics_subnet_ids = []

vpn_clients_security_group_id = "sg-00ed1861c994de17f"

eks_cluster_name                   = "interop-eks-cluster-att"
eks_cluster_node_security_group_id = "sg-06a319760e093d017"

redshift_cluster_nodes_number = 2
redshift_cluster_nodes_type   = "ra3.xlplus"

jwt_details_bucket_name = "interop-generated-jwt-details-att-es1"
alb_logs_bucket_name    = "interop-alb-logs-att-es1"

jwt_details_s3_events_topic_name = "interop-jwt-details-new-s3-object-att"

analytics_k8s_namespace = "att-analytics"

deployment_repo_name = "pagopa/interop-analytics-deployment"

s3_reprocess_repo_name = "pagopa/interop-s3-reprocess"

github_runner_task_role_name = "interop-github-runner-task-att-es1"

msk_cluster_name = "interop-platform-events-att"

msk_monitoring_app_audit_max_offset_lag_threshold = 500
msk_monitoring_app_audit_evaluation_periods       = 5
msk_monitoring_app_audit_period_seconds           = 60

application_audit_producers_irsa_list = [
  "interop-be-agreement-process-att-es1",
  "interop-be-api-gateway-att-es1",
  "interop-be-authorization-server-att-es1",
  "interop-be-backend-for-frontend-att-es1",
  "interop-be-catalog-process-att-es1",
  "interop-be-delegation-process-att-es1",
  "interop-be-m2m-gateway-att-es1",
  "interop-be-purpose-process-att-es1",
  "interop-be-tenant-process-att-es1"
]
