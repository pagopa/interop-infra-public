locals {
  eks_secret_default_tags = {
    EKSClusterName                     = module.eks.cluster_name
    EKSClusterNamespacesSpaceSeparated = join(" ", [var.env])
    TerraformState                     = local.terraform_state
  }
}

module "platform_data_flyway_pgsql_user" {
  count = local.deploy_read_model_refactor ? 1 : 0

  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.22.1"

  username = "flyway_user"

  generated_password_length = 30
  secret_prefix             = format("rds/%s/users/", module.platform_data.cluster_id)

  secret_tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "platform-data-flyway-user"
    }
  )

  db_host = module.platform_data.cluster_endpoint
  db_port = module.platform_data.cluster_port
  db_name = "read_model" # PG roles are "global", we just a need an existing database

  db_admin_credentials_secret_arn = module.platform_data.cluster_master_user_secret[0].secret_arn

  additional_sql_statements = <<-EOT
    GRANT CREATE ON DATABASE "persistence_management" TO "flyway_user";
    GRANT CREATE ON DATABASE "read_model" TO "flyway_user";
    GRANT CREATE ON DATABASE "in_app_notification" TO "flyway_user";
  EOT
}

module "platform_data_readonly_pgsql_user" {
  count      = local.deploy_read_model_refactor ? 1 : 0
  depends_on = [module.platform_data_flyway_pgsql_user]

  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.22.1"

  username = "readonly_user"

  generated_password_length = 30
  secret_prefix             = format("rds/%s/users/", module.platform_data.cluster_id)

  secret_tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "platform-data-readonly-user"
    }
  )

  db_host = module.platform_data.cluster_endpoint
  db_port = module.platform_data.cluster_port
  db_name = "read_model" # PG roles are "global", we just a need an existing database

  db_admin_credentials_secret_arn = module.platform_data.cluster_master_user_secret[0].secret_arn

  additional_sql_statements = <<-EOT
    ALTER DEFAULT PRIVILEGES GRANT USAGE ON SCHEMAS TO readonly_user;
    ALTER DEFAULT PRIVILEGES GRANT SELECT ON TABLES TO readonly_user;
    ALTER DEFAULT PRIVILEGES GRANT SELECT ON SEQUENCES TO readonly_user;
  EOT
}

locals {
  be_app_psql_usernames = local.deploy_read_model_refactor ? [
    "agreement_process_user",
    "agreement_rmw_user",
    "anac_certified_attributes_importer_user",
    "api_gateway_user",
    "attribute_registry_process_user",
    "attribute_registry_rmw_user",
    "authorization_process_user",
    "catalog_process_user",
    "catalog_rmw_user",
    "certified_email_sender_user",
    "client_rmw_user",
    "datalake_data_export_user",
    "delegation_items_archiver_user",
    "delegation_process_user",
    "delegation_rmw_user",
    "dtd_catalog_exporter_user",
    "eservice_descriptors_archiver_user",
    "eservice_template_instances_updater_user",
    "eservice_template_process_user",
    "eservice_template_rmw_user",
    "in_app_notification_manager_user",
    "in_app_notification_dispatcher_user",
    "ipa_certified_attributes_importer_user",
    "ivass_certified_attributes_importer_user",
    "key_rmw_user",
    "m2m_event_dispatcher_user",
    "m2m_event_manager_user",
    "notification_config_process_user",
    "notification_config_rmw_user",
    "notification_email_sender_user",
    "pn_consumers_user",
    "producer_key_rmw_user",
    "producer_keychain_rmw_user",
    "purpose_process_user",
    "purpose_rmw_user",
    "purpose_template_process_user",
    "purpose_template_rmw_user",
    "selfcare_client_users_updater_user",
    "tenant_process_user",
    "tenant_rmw_user",
    "token_generation_readmodel_checker_user"
  ] : []
}


# PostgreSQL users with no initial grants. The grants will be applied by Flyway
module "platform_data_be_app_pgsql_user" {
  source     = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.22.1"
  depends_on = [module.platform_data_flyway_pgsql_user]

  for_each = toset(local.be_app_psql_usernames)

  username = format("%s_%s", var.env, each.value)

  generated_password_length = 30
  secret_prefix             = format("rds/%s/users/", module.platform_data.cluster_id)

  secret_tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = format("platform-data-%s", replace(each.value, "_", "-"))
    }
  )

  db_host = module.platform_data.cluster_endpoint
  db_port = module.platform_data.cluster_port
  db_name = "read_model" # PG roles are "global", we just a need an existing database

  db_admin_credentials_secret_arn = module.platform_data.cluster_master_user_secret[0].secret_arn
}

module "platform_data_kpi_domains_readmodel_checker_pgsql_user" {
  count      = local.deploy_read_model_refactor ? 1 : 0
  depends_on = [module.platform_data_readonly_pgsql_user]

  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.22.1"

  username = "kpi_domains_readmodel_checker_user"

  generated_password_length = 30
  secret_prefix             = format("rds/%s/users/", module.platform_data.cluster_id)

  secret_tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "kpi-domains-readmodel-checker-user"
    }
  )

  db_host = module.platform_data.cluster_endpoint
  db_port = module.platform_data.cluster_port
  db_name = "read_model" # PG roles are "global", we just a need an existing database

  db_admin_credentials_secret_arn = module.platform_data.cluster_master_user_secret[0].secret_arn

  additional_sql_statements = <<-EOT
    GRANT readonly_user TO kpi_domains_readmodel_checker_user;
  EOT
}

locals {
  eks_kpi_domains_readmodel_checker_analytics_replica_secret_tags = {
    EKSClusterName                     = module.eks.cluster_name
    EKSClusterNamespacesSpaceSeparated = join(" ", [format("%s-analytics", var.env)])
    TerraformState                     = "analytics"
  }
}

# This secret is useful to replicate the 'kpi_domains_readmodel_checker_user' secret on the ${ENV}-analytics namespace which is managed by the analytics TF state
resource "aws_secretsmanager_secret" "kpi_domains_readmodel_checker_user_analytics_replica" {
  count      = local.deploy_read_model_refactor ? 1 : 0
  depends_on = [module.platform_data_kpi_domains_readmodel_checker_pgsql_user]

  name                    = format("rds/%s/users/kpi_domains_readmodel_checker_user_analytics_replica", module.platform_data.cluster_id)
  description             = "This secret is useful to replicate the already existing 'kpi_domains_readmodel_checker_user' secret on the ${var.env}-analytics namespace which is managed by the analytics TF state"
  recovery_window_in_days = 0

  tags = merge(local.eks_kpi_domains_readmodel_checker_analytics_replica_secret_tags,
    {
      EKSReplicaSecretName = "kpi-domains-readmodel-checker-user"
    }
  )
}

data "aws_secretsmanager_secret_version" "kpi_domains_readmodel_checker_user_analytics_replica" {
  secret_id = module.platform_data_kpi_domains_readmodel_checker_pgsql_user[0].secret_id
}

resource "aws_secretsmanager_secret_version" "kpi_domains_readmodel_checker_user_analytics_replica" {
  count      = local.deploy_read_model_refactor ? 1 : 0
  depends_on = [module.platform_data_kpi_domains_readmodel_checker_pgsql_user]

  secret_id = aws_secretsmanager_secret.kpi_domains_readmodel_checker_user_analytics_replica[0].id

  secret_string = jsonencode({
    database = "read_model"
    username = "kpi_domains_readmodel_checker_user"
    password = jsondecode(data.aws_secretsmanager_secret_version.kpi_domains_readmodel_checker_user_analytics_replica.secret_string)["password"]
  })
}

locals {
  eks_public_catalog_updater_replica_secret_tags = {
    EKSClusterName                     = module.eks.cluster_name
    EKSClusterNamespacesSpaceSeparated = join(" ", [format("%s-public-catalog", var.env)])
    TerraformState                     = "public-catalog"
  }
}

module "platform_data_public_catalog_updater_pgsql_user" {
  count      = local.deploy_read_model_refactor ? 1 : 0
  depends_on = [module.platform_data_readonly_pgsql_user]

  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.22.1"

  username = "public_catalog_updater_user"

  generated_password_length = 30
  secret_prefix             = format("rds/%s/users/", module.platform_data.cluster_id)

  secret_tags = merge(local.eks_public_catalog_updater_replica_secret_tags,
    {
      EKSReplicaSecretName = "platform-data-public-catalog-updater-user"
    }
  )

  db_host = module.platform_data.cluster_endpoint
  db_port = module.platform_data.cluster_port
  db_name = "read_model" # PG roles are "global", we just a need an existing database

  db_admin_credentials_secret_arn = module.platform_data.cluster_master_user_secret[0].secret_arn
}
