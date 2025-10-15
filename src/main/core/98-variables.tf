variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "short_name" {
  type        = string
  description = "Project short name used in resource names"
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

variable "platform_data_database_name" {
  description = "SQL database name in the Aurora cluster platform data"
  type        = string
}

variable "platform_data_engine_version" {
  description = "Engine version of the Aurora cluster - platform data"
  type        = string
}

variable "platform_data_ca_cert_id" {
  description = "ID of the Certificate Authority to apply to db instances for SSL connections"
  type        = string
}

variable "platform_data_instance_class" {
  description = "Instance class of the Aurora cluster - platform data"
  type        = string
}

variable "platform_data_number_instances" {
  description = "Number of instances of the Aurora cluster - platform data"
  type        = number

  validation {
    condition     = var.platform_data_number_instances > 0
    error_message = "The number of instances must be greater than 0"
  }
}

variable "platform_data_parameter_group_family" {
  description = "Family of the DB parameter group for Aurora cluster - platform data"
  type        = string
}

variable "platform_data_master_username" {
  description = "Master username - platform data"
  type        = string
}

variable "read_model_cluster_id" {
  description = "DocDB cluster ID - read model"
  type        = string
}

variable "read_model_master_username" {
  description = "Master username - read model"
  type        = string
}

variable "read_model_engine_version" {
  description = "Engine version of the DocDB cluster - read model"
  type        = string
}

variable "read_model_db_port" {
  description = "DB port of the DocDB cluster - read model"
  type        = string
  default     = 27017
}

variable "read_model_instance_class" {
  description = "Instance class of the DocDB cluster - read model"
  type        = string
}

variable "read_model_ca_cert_id" {
  description = "ID of the Certificate Authority to apply to db instances for SSL connections"
  type        = string
}

variable "read_model_number_instances" {
  description = "Number of instances of the DocDB cluster - read model"
  type        = number
}

variable "read_model_parameter_group_family" {
  description = "Family of the parameter group (based on engine version) for the DocDB cluster - read model"
  type        = map(any)
  default = {
    "3.6.0" = "docdb3.6"
    "4.0.0" = "docdb4.0"
  }
}

variable "msk_version" {
  description = "Kafka cluster version"
  type        = string
}

variable "msk_number_azs" {
  description = "Number of AZs to use for the MSK cluster"
  type        = number
}

variable "msk_number_brokers" {
  description = "Kafka cluster number of brokers - MUST be a multiple of the number of AZs used by the cluster"
  type        = number
}

variable "msk_brokers_instance_class" {
  description = "Kafka cluster brokers instance class"
  type        = string
}

variable "msk_brokers_storage_gib" {
  description = "Kafka cluster brokers EBS volume storage (GiB)"
  type        = number

  validation {
    condition     = var.msk_brokers_storage_gib > 0
    error_message = "The EBS volume size of Kafka brokers must be > 0"
  }
}

variable "msk_signalhub_account_id" {
  description = "SignalHub account ID for MSK cluster access"
  type        = string
  default     = null
}

variable "msk_tracing_account_id" {
  description = "Tracing account ID for MSK cluster access"
  type        = string
  default     = null
}

variable "msk_probing_account_id" {
  description = "Probing account ID for MSK cluster access"
  type        = string
  default     = null
}

variable "notification_events_table_ttl_enabled" {
  description = "Enable or disable TTL in 'interop-notification-events' table"
  type        = bool
}

variable "github_runners_allowed_repos" {
  description = "Github repositories names (format: organization/repo-name) allowed to assume the ECS role to start/stop self-hosted runners"
  type        = list(string)
}

variable "github_runners_cpu" {
  description = "vCPU to allocate for each GH runner execution (e.g. 1024)"
  type        = number
}

variable "github_runners_memory" {
  description = "RAM to allocate for each GH runner execution (e.g. 2048)"
  type        = number
}

variable "github_runners_image_uri" {
  description = "URI of the runner image"
  type        = string
}

variable "dns_interop_base_domain" {
  description = "Base DNS domain for the Interoperability product. According to PagoPA eng standard, it usually is a third level domain (e.g. product.example.com)"
  type        = string
}

variable "dns_api_gov_domain" {
  description = "Domain for API GOV hosted zone"
  type        = string
  default     = null
}

variable "dns_interop_gov_domain" {
  description = "Domain for Interop GOV hosted zone"
  type        = string
  default     = null
}

variable "dns_pdnd_gov_domain" {
  description = "Domain for PDND GOV hosted zone"
  type        = string
  default     = null
}

variable "dns_interop_dev_ns_records" {
  description = "NS records for the Interop 'dev' hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "dns_interop_uat_ns_records" {
  description = "NS records for the Interop 'uat' hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "dns_interop_qa_ns_records" {
  description = "NS records for the Interop 'qa' hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "dns_interop_vapt_ns_records" {
  description = "NS records for the Interop 'vapt' hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "dns_interop_att_ns_records" {
  description = "NS records for the Interop 'att' hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "dns_interop_att_sandbox_ns_records" {
  description = "NS records for the Interop 'att' SANDBOX hosted zone. Used to grant DNS delegation for the subdomain"
  type        = list(string)
  default     = []
}

variable "data_lake_account_id" {
  description = "AWS account ID of the DataLake team for token data ingestion"
  type        = string
  default     = null
}

variable "data_lake_external_id" {
  description = "External ID of the DataLake team for token data ingestion. Passed by them when assuming the role"
  type        = string
  default     = null
}

variable "data_lake_interfaces_bucket_arn" {
  description = "ARN of the DataLake interfaces bucket"
  type        = string
  default     = null
}

variable "probing_registry_reader_role_arn" {
  description = "ARN of the role used by the probing registry reader to access the bucket containing eservices list"
  type        = string
  default     = null
}

variable "probing_domain_ns_records" {
  description = "NS records for the probing DNS domain"
  type        = list(string)
  default     = []
}

variable "signalhub_domain_ns_records" {
  description = "NS records for the SignalHub DNS domain"
  type        = list(string)
  default     = []
}

variable "tracing_domain_ns_records" {
  description = "NS records for the Tracing DNS domain"
  type        = list(string)
  default     = []
}

variable "interop_auth_openapi_path" {
  description = "Relative path of Interop auth OpenAPI definition file"
  type        = string
}

variable "interop_api_openapi_path" {
  description = "Relative path of Interop API OpenAPI definition file"
  type        = string
}

variable "interop_api_v2_openapi_path" {
  description = "Relative path of Interop API v2 OpenAPI definition file"
  type        = string
  default     = null
}

variable "interop_bff_openapi_path" {
  description = "Relative path of Interop BFF OpenAPI definition file"
  type        = string
}

variable "interop_bff_proxy_openapi_path" {
  description = "Relative path of Interop BFF proxy OpenAPI definition file"
  type        = string
}

variable "interop_frontend_assets_openapi_path" {
  description = "Relative path of Interop Frontend Assets OpenAPI definition file"
  type        = string
}

variable "interop_landing_domain_name" {
  description = "Domain name of the Interop landing page"
  type        = string
}

variable "eks_k8s_version" {
  type        = string
  description = "K8s version used in the EKS cluster"
}

variable "eks_vpc_cni_version" {
  type        = string
  description = "EKS vpc-cni addon version"
  default     = null
}

variable "eks_coredns_version" {
  type        = string
  description = "EKS coredns addon version"
  default     = null
}

variable "eks_kube_proxy_version" {
  type        = string
  description = "EKS kube-proxy addon version"
  default     = null
}

variable "backend_integration_alb_name" {
  description = ""
  type        = string
}

variable "eks_application_log_group_name" {
  description = "Name of the application log group created by FluentBit"
  type        = string
  default     = null
}

variable "vpn_saml_metadata_path" {
  description = "Path to the SAML metadata XML file. Used when federated authentication for VPN is enabled"
  type        = string
  default     = null
}

variable "k8s_monitoring_deployments_names" {
  description = "Names of K8s deployments to monitor using HTTP status codes through APIGW"
  type        = list(string)
  default     = []
}

variable "k8s_monitoring_internal_deployments_names" {
  description = "Names of K8s deployments to monitor using application logs instead of HTTP requests"
  type        = list(string)
  default     = []
}

variable "k8s_monitoring_cronjobs_names" {
  description = "Names of K8s cronjobs to monitor"
  type        = list(string)
  default     = []
}

variable "be_refactor_k8s_monitoring_deployments_names" {
  description = "Names of K8s deployments (be-refactor) to monitor using HTTP status codes through APIGW"
  type        = list(string)
  default     = []
}

variable "be_refactor_k8s_monitoring_internal_deployments_names" {
  description = "Names of K8s deployments (be-refactor) to monitor using application logs instead of HTTP requests"
  type        = list(string)
  default     = []
}

variable "be_refactor_k8s_monitoring_cronjobs_names" {
  description = "Names of K8s cronjobs (be-refactor) to monitor"
  type        = list(string)
  default     = []
}

variable "deployment_repo_name" {
  description = "Github repository name containing deployment automation (format: organization/repo-name)"
  type        = string
}

variable "be_monorepo_name" {
  description = "Github repository name containing backend code (format: organization/repo-name)"
  type        = string
}

variable "generic_development_repos_names" {
  description = "Github repositories names used for development (format: organization/repo-name)"
  type        = list(string)
}

variable "analytics_k8s_namespace" {
  description = "Kubernetes namespace for the Analytics project"
  type        = string
  default     = null
}

variable "public_catalog_k8s_namespace" {
  description = "Kubernetes namespace for the Public Catalog project"
  type        = string
  default     = null
}
