locals {
  eks_secret_default_tags = {
    EKSClusterName                     = data.aws_eks_cluster.core.name
    EKSClusterNamespacesSpaceSeparated = join(" ", [var.analytics_k8s_namespace])
    TerraformState                     = local.terraform_state
  }

  # The following locals are useful to define the Redshift cluster connection parameters in case of a cross-account Redshift cluster
  redshift_host         = try(local.deploy_redshift_cluster ? element(split(":", aws_redshift_cluster.analytics[0].endpoint), 0) : data.aws_redshift_cluster.cross_account[0].endpoint, null)
  redshift_cluster_name = try(local.deploy_redshift_cluster ? aws_redshift_cluster.analytics[0].cluster_identifier : data.aws_redshift_cluster.cross_account[0].cluster_identifier, null)
  redshift_port         = try(local.deploy_redshift_cluster ? aws_redshift_cluster.analytics[0].port : data.aws_redshift_cluster.cross_account[0].port, null)
  redshift_database     = try(local.deploy_redshift_cluster ? aws_redshift_cluster.analytics[0].database_name : var.redshift_cross_account_cluster.database_name, null)

  redshift_master_user_secret_arn = try(local.deploy_redshift_cluster ? aws_secretsmanager_secret.redshift_master[0].arn : data.aws_secretsmanager_secret.redshift_master_cross_account[0].arn, null)
}

module "redshift_flyway_pgsql_user" {
  count = anytrue([local.deploy_redshift_cluster, local.deploy_all_data_ingestion_resources, local.deploy_redshift_cross_account]) ? 1 : 0

  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.27.6"

  username = format("%s_flyway_user", var.env)

  generated_password_length = 30
  secret_prefix             = format("redshift/%s/users/", local.redshift_cluster_name)

  secret_tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "redshift-flyway-user"
    }
  )

  redshift_cluster = true

  db_host = local.redshift_host
  db_port = local.redshift_port
  db_name = local.redshift_database

  db_admin_credentials_secret_arn = local.redshift_master_user_secret_arn

  additional_sql_statements = <<-EOT
    GRANT CREATE ON DATABASE ${local.redshift_database} TO "${format("%s_flyway_user", var.env)}";
    ALTER USER "${format("%s_flyway_user", var.env)}" SET search_path TO '\$user';
  EOT
}

locals {
  redshift_users_json_data = jsondecode(file("./assets/redshift-users/redshift-users-${var.env}.json"))

  be_app_psql_usernames = try([
    for user in local.redshift_users_json_data.be_app_users : user
  ], [])

  readonly_psql_usernames = try([
    for user in local.redshift_users_json_data.readonly_users : user
  ], [])
}

# PostgreSQL users with no initial grants. The grants will be applied by Flyway
module "redshift_be_app_pgsql_user" {
  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.27.6"

  for_each = toset(local.be_app_psql_usernames)

  username = format("%s_%s", var.env, each.value)

  generated_password_length = 30
  secret_prefix             = format("redshift/%s/users/", local.redshift_cluster_name)

  secret_tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = format("redshift-%s", replace(each.value, "_", "-"))
    }
  )

  redshift_cluster = true

  db_host = local.redshift_host
  db_port = local.redshift_port
  db_name = local.redshift_database

  db_admin_credentials_secret_arn = local.redshift_master_user_secret_arn
}

# PostgreSQL users for developers with default privileges.
module "redshift_readonly_pgsql_user" {
  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.27.6"

  for_each = toset(local.readonly_psql_usernames)

  username = each.value

  generated_password_length = 30
  secret_prefix             = format("redshift/%s/users/", local.redshift_cluster_name)

  secret_tags = merge(var.tags, {
    Redshift = "" # Necessary for Redshift log-in integration when using Quey editor v2
  })

  redshift_cluster = true

  db_host = local.redshift_host
  db_port = local.redshift_port
  db_name = local.redshift_database

  db_admin_credentials_secret_arn = local.redshift_master_user_secret_arn

  grant_redshift_groups = ["readonly_group"]

  additional_sql_statements = <<-EOT
    ALTER DEFAULT PRIVILEGES FOR USER ${format("%s_flyway_user", var.env)} GRANT SELECT ON TABLES TO GROUP readonly_group;
  EOT
}

module "redshift_quicksight_pgsql_user" {
  count = local.deploy_redshift_cluster ? 1 : 0

  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.27.6"

  username = "${var.env}_quicksight_user"

  generated_password_length = 30
  secret_prefix             = format("redshift/%s/users/", local.redshift_cluster_name)

  secret_tags = merge(var.tags, {
    Redshift = "" # Necessary for Redshift log-in integration when using Quey editor v2
  })

  redshift_cluster = true

  db_host = local.redshift_host
  db_port = local.redshift_port
  db_name = local.redshift_database

  db_admin_credentials_secret_arn = local.redshift_master_user_secret_arn
}

module "redshift_mv_refresher_user" {
  count = local.deploy_redshift_cluster ? 1 : 0

  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/postgresql-user?ref=v1.27.6"

  # local from './20-redshift-refresh-materialized-views.tf' file
  username = local.mv_refresher_redshift_db_user

  generated_password_length = 30
  secret_prefix             = format("redshift/%s/users/", local.redshift_cluster_name)

  secret_tags = merge(var.tags, {
    Redshift = "" # Necessary for Redshift log-in integration when using Quey editor v2
  })

  redshift_cluster = true

  db_host = local.redshift_host
  db_port = local.redshift_port
  db_name = local.redshift_database

  db_admin_credentials_secret_arn = local.redshift_master_user_secret_arn

  # this user do not need UNrestricted syslog access because it use stored procedure with 
  # "security definer" and created by the flyway migration user; the same user that own 
  # materialized views and other objects that we need information for.
  additional_sql_statements = <<-EOT
    ALTER USER "${format("%s_mv_refresher_user", var.env)}" WITH SYSLOG ACCESS RESTRICTED;
  EOT

}