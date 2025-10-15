aws_region = "eu-south-1"
env        = "test"
short_name = "interop"
azs        = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]

tags = {
  CreatedBy   = "Terraform"
  Environment = "test"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-infra"
}

sso_admin_role_name = ""

platform_data_database_name          = "persistence_management"
platform_data_engine_version         = "13.9"
platform_data_ca_cert_id             = "rds-ca-rsa2048-g1"
platform_data_instance_class         = "db.t4g.medium"
platform_data_number_instances       = 3
platform_data_parameter_group_family = "aurora-postgresql13"
platform_data_master_username        = "root"

read_model_cluster_id       = "read-model"
read_model_master_username  = "root"
read_model_engine_version   = "4.0.0"
read_model_instance_class   = "db.r6g.large"
read_model_ca_cert_id       = "rds-ca-rsa2048-g1"
read_model_number_instances = 0

msk_version                = "3.6.0"
msk_number_azs             = 3
msk_number_brokers         = 3
msk_brokers_instance_class = "kafka.m5.large"
msk_brokers_storage_gib    = 100
msk_signalhub_account_id   = ""
msk_tracing_account_id     = ""

notification_events_table_ttl_enabled = true

backend_integration_alb_name = "k8s-interopbe-d20020e3b0"

github_runners_allowed_repos = []
github_runners_cpu           = 2048
github_runners_memory        = 4096
github_runners_image_uri     = "ghcr.io/pagopa/interop-github-runner-aws:v1.19.2"

dns_interop_base_domain = "interop.pagopa.it"

interop_frontend_assets_openapi_path = "./openapi/test/interop-frontend-assets-integrated.yaml"
interop_bff_proxy_openapi_path       = "./openapi/interop-backend-for-frontend-proxy.yaml"
interop_bff_openapi_path             = "./openapi/interop-backend-for-frontend-proxy.yaml"
interop_auth_openapi_path            = "./openapi/test/interop-auth-server.yaml"
interop_api_openapi_path             = "./openapi/test/interop-api-v1.0.yaml"
interop_api_v2_openapi_path          = "./openapi/test/interop-api-v2.yaml"

interop_landing_domain_name = "uat.interop.pagopa.it"

lambda_eks_application_log_group_arn = ""

eks_k8s_version = "1.32"

backend_integration_v2_alb_name = ""

eks_application_log_group_name = "/aws/eks/interop-eks-cluster-test/application"

# deployments which require monitoring from application logs instead of HTTP requests
k8s_monitoring_internal_deployments_names = [
  "debezium-postgresql"
]

deployment_repo_name = ""
be_monorepo_name     = ""

generic_development_repos_names = [
]

