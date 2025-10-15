aws_region = "eu-south-1"
env        = "test"
azs        = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]

tags = {
  CreatedBy   = "Terraform"
  Environment = "test"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-infra"
}

sso_admin_role_name = "AWSReservedSSO_FullAdmin_48811da36f58fc1e"

vpc_id               = "vpc-0c5b2136663fe87de"
analytics_subnet_ids = []

vpn_clients_security_group_id = "sg-05dff87e0345917ac"

eks_cluster_name                   = "interop-eks-cluster-test"
eks_cluster_node_security_group_id = "sg-018dcdbb6f3f7f4d0"

redshift_cluster_nodes_number = 2
redshift_cluster_nodes_type   = "ra3.xlplus"

jwt_details_bucket_name = "interop-generated-jwt-details-test-es1"
alb_logs_bucket_name    = "interop-alb-logs-test-es1"

jwt_details_s3_events_topic_name = "interop-jwt-details-new-s3-object-test"

analytics_k8s_namespace = "test-analytics"

deployment_repo_name = "pagopa/interop-analytics-deployment"

s3_reprocess_repo_name = "pagopa/interop-s3-reprocess"

github_runner_task_role_name = "interop-github-runner-task-test-es1"

msk_cluster_name = "interop-platform-events-test"

msk_monitoring_app_audit_max_offset_lag_threshold = 500
msk_monitoring_app_audit_evaluation_periods       = 5
msk_monitoring_app_audit_period_seconds           = 60

application_audit_producers_irsa_list = [
  "interop-be-agreement-process-test-es1",
  "interop-be-api-gateway-test-es1",
  "interop-be-authorization-server-test-es1",
  "interop-be-backend-for-frontend-test-es1",
  "interop-be-catalog-process-test-es1",
  "interop-be-delegation-process-test-es1",
  "interop-be-m2m-gateway-test-es1",
  "interop-be-purpose-process-test-es1",
  "interop-be-tenant-process-test-es1"
]
