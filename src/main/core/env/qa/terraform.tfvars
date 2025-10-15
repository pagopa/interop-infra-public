aws_region = "eu-south-1"
env        = "qa"
short_name = "interop"
azs        = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]

tags = {
  CreatedBy   = "Terraform"
  Environment = "Qa"
  Owner       = "Interoperabilità"
  CostCenter  = "TS620 Interoperabilità"
  Source      = "https://github.com/pagopa/interop-infra"
}

sso_admin_role_name = ""

platform_data_database_name          = "persistence_management"
platform_data_engine_version         = "13.20"
platform_data_ca_cert_id             = "rds-ca-rsa2048-g1"
platform_data_instance_class         = "db.t4g.medium"
platform_data_number_instances       = 3
platform_data_parameter_group_family = "aurora-postgresql13"
platform_data_master_username        = "root"

read_model_cluster_id       = "read-model"
read_model_master_username  = "root"
read_model_engine_version   = "4.0.0"
read_model_instance_class   = "db.t4g.medium"
read_model_ca_cert_id       = "rds-ca-rsa2048-g1"
read_model_number_instances = 0

msk_version                = "3.6.0"
msk_number_azs             = 3
msk_number_brokers         = 3
msk_brokers_instance_class = "kafka.m5.large"
msk_brokers_storage_gib    = 100
msk_signalhub_account_id   = ""

notification_events_table_ttl_enabled = true

github_runners_allowed_repos = []
github_runners_cpu           = 2048
github_runners_memory        = 4096
github_runners_image_uri     = "ghcr.io/pagopa/interop-github-runner-aws:v1.19.2"

dns_interop_base_domain = "interop.pagopa.it"

interop_frontend_assets_openapi_path = "./openapi/qa/interop-frontend-assets-integrated.yaml"
interop_bff_proxy_openapi_path       = "./openapi/interop-backend-for-frontend-proxy.yaml"
interop_bff_openapi_path             = "./openapi/interop-backend-for-frontend-proxy.yaml"
interop_auth_openapi_path            = "./openapi/qa/interop-auth-server.yaml"
interop_api_openapi_path             = "./openapi/qa/interop-api-v1.0.yaml"
interop_api_v2_openapi_path          = "./openapi/qa/interop-api-v2.yaml"

interop_landing_domain_name = "qa.interop.pagopa.it"

eks_k8s_version        = "1.29"
eks_vpc_cni_version    = "v1.16.0-eksbuild.1"
eks_coredns_version    = "v1.11.1-eksbuild.4"
eks_kube_proxy_version = "v1.29.0-eksbuild.1"

backend_integration_alb_name = ""

eks_application_log_group_name = "/aws/eks/interop-eks-cluster-qa/application"

# deployments which require monitoring from application logs instead of HTTP requests
k8s_monitoring_internal_deployments_names = [
  "debezium-postgresql",
]

deployment_repo_name = ""
be_monorepo_name     = ""

generic_development_repos_names = [
]

public_catalog_k8s_namespace = "qa-public-catalog"
