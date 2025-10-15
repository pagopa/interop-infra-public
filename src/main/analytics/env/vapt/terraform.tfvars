aws_region = "eu-south-1"
env        = "vapt"
azs        = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]

tags = {
  CreatedBy   = "Terraform"
  Environment = "vapt"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-infra"
}

sso_admin_role_name = "AWSReservedSSO_FullAdmin_92bf78ef453cd095"

vpc_id               = "vpc-01acd5bfcd5584b70"
analytics_subnet_ids = []

vpn_clients_security_group_id = "sg-0ee0710b283ed81ff"

eks_cluster_name                   = "interop-eks-cluster-vapt"
eks_cluster_node_security_group_id = "sg-06818282d0e82937f"

redshift_cluster_nodes_number = 2
redshift_cluster_nodes_type   = "ra3.xlplus"

jwt_details_bucket_name = "interop-generated-jwt-details-vapt-es1"
alb_logs_bucket_name    = "interop-alb-logs-vapt-es1"

jwt_details_s3_events_topic_name = "interop-jwt-details-new-s3-object-vapt"

analytics_k8s_namespace = "vapt-analytics"

deployment_repo_name = "pagopa/interop-analytics-deployment"

s3_reprocess_repo_name = "pagopa/interop-s3-reprocess"

github_runner_task_role_name = "interop-github-runner-task-vapt-es1"

msk_cluster_name = "interop-platform-events-vapt"

msk_monitoring_app_audit_max_offset_lag_threshold = 500
msk_monitoring_app_audit_evaluation_periods       = 5
msk_monitoring_app_audit_period_seconds           = 60

application_audit_producers_irsa_list = [
  "interop-be-agreement-process-vapt-es1",
  "interop-be-api-gateway-vapt-es1",
  "interop-be-authorization-server-vapt-es1",
  "interop-be-backend-for-frontend-vapt-es1",
  "interop-be-catalog-process-vapt-es1",
  "interop-be-delegation-process-vapt-es1",
  "interop-be-m2m-gateway-vapt-es1",
  "interop-be-purpose-process-vapt-es1",
  "interop-be-tenant-process-vapt-es1"
]
