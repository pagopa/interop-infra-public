resource "aws_secretsmanager_secret" "redshift_master" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name = format("redshift/%s-analytics-%s/users/%s", local.project, var.env, var.redshift_master_username)

  # Necessary for Redshift log in integration
  tags = merge(var.tags, {
    Redshift = ""
  })
}

data "aws_secretsmanager_random_password" "redshift_master" {
  count = local.deploy_redshift_cluster ? 1 : 0

  password_length            = 30
  exclude_characters         = "\"@/'\\ "
  require_each_included_type = true
}

resource "aws_secretsmanager_secret_version" "redshift_master" {
  count = local.deploy_redshift_cluster ? 1 : 0

  secret_id = aws_secretsmanager_secret.redshift_master[0].id
  secret_string = jsonencode({
    username = var.redshift_master_username
    password = data.aws_secretsmanager_random_password.redshift_master[0].random_password
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_kms_key" "analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_kms_alias" "analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name          = format("alias/redshift/%s-analytics-%s", local.project, var.env)
  target_key_id = aws_kms_key.analytics[0].key_id
}

resource "aws_redshift_parameter_group" "analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name   = format("%s-analytics-%s", local.project, var.env)
  family = "redshift-1.0"
}

resource "aws_cloudwatch_log_group" "connectionlog" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name = format("/aws/redshift/cluster/%s-analytics-%s/connectionlog", local.project, var.env)

  retention_in_days = var.env == "prod" ? 90 : 30
  skip_destroy      = true
}

resource "aws_cloudwatch_log_group" "useractivitylog" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name = format("/aws/redshift/cluster/%s-analytics-%s/useractivitylog", local.project, var.env)

  retention_in_days = var.env == "prod" ? 90 : 30
  skip_destroy      = true
}

resource "aws_cloudwatch_log_group" "userlog" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name = format("/aws/redshift/cluster/%s-analytics-%s/userlog", local.project, var.env)

  retention_in_days = var.env == "prod" ? 90 : 30
  skip_destroy      = true
}

resource "aws_redshift_logging" "analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  depends_on = [aws_cloudwatch_log_group.connectionlog[0], aws_cloudwatch_log_group.useractivitylog[0], aws_cloudwatch_log_group.userlog[0]]

  cluster_identifier   = aws_redshift_cluster.analytics[0].id
  log_destination_type = "cloudwatch"
  log_exports          = ["connectionlog", "useractivitylog", "userlog"]
}

resource "aws_redshift_cluster" "analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  cluster_identifier = format("%s-analytics-%s", local.project, var.env)
  database_name      = format("%s_%s", local.project, var.env)

  #Workaround because the Redshift's managed secret for the master is not removed when the cluster is deleted.
  #Issue: https://repost.aws/questions/QUCWqC0PYJS0-zGINN-PEzlw/how-do-we-delete-secrets-manager-secrets-created-by-the-redshift-integration
  master_username = jsondecode(aws_secretsmanager_secret_version.redshift_master[0].secret_string).username
  master_password = jsondecode(aws_secretsmanager_secret_version.redshift_master[0].secret_string).password

  cluster_type    = "multi-node"
  number_of_nodes = var.redshift_cluster_nodes_number
  node_type       = var.redshift_cluster_nodes_type

  cluster_subnet_group_name = aws_redshift_subnet_group.analytics[0].name
  multi_az                  = false
  vpc_security_group_ids    = [aws_security_group.analytics[0].id]

  availability_zone_relocation_enabled = true

  publicly_accessible = false
  port                = var.redshift_cluster_port

  cluster_parameter_group_name = aws_redshift_parameter_group.analytics[0].name

  encrypted  = true
  kms_key_id = aws_kms_key.analytics[0].arn

  enhanced_vpc_routing = true

  allow_version_upgrade = false

  skip_final_snapshot = true

  iam_roles = [aws_iam_role.redshift_s3_copy.arn]
}

locals {
  databases_to_create = local.deploy_redshift_cluster ? [
    for db in var.redshift_databases_to_create : db if db != aws_redshift_cluster.analytics[0].database_name # Exclude the already existing database from the list of databases to create
  ] : []
}

# Create a database in the Redshift cluster for each entry in the databases_to_create list (excluding the the already existing database because it has already been created by the aws_redshift_cluster.a resource)
resource "null_resource" "analytics_create_db" {
  depends_on = [aws_redshift_cluster.analytics[0], aws_secretsmanager_secret.redshift_master[0]]

  for_each = toset(local.databases_to_create)

  provisioner "local-exec" {
    environment = {
      HOST                         = element(split(":", aws_redshift_cluster.analytics[0].endpoint), 0)
      DATABASE                     = aws_redshift_cluster.analytics[0].database_name
      DATABASE_PORT                = aws_redshift_cluster.analytics[0].port
      DATABASE_TO_CREATE           = each.key
      ADMIN_CREDENTIALS_SECRET_ARN = aws_secretsmanager_secret.redshift_master[0].arn
    }

    command = <<EOT
      #!/bin/bash
      set -euo pipefail

      secret_json=$(aws secretsmanager get-secret-value --secret-id $ADMIN_CREDENTIALS_SECRET_ARN --query SecretString --output text)

      ADMIN_USERNAME=$(echo $secret_json | jq -r '.username')
      ADMIN_PASSWORD=$(echo $secret_json | jq -r '.password')

      export PGPASSWORD=$ADMIN_PASSWORD

      DB_EXISTS=$(psql --host "$HOST" --username "$ADMIN_USERNAME" --port "$DATABASE_PORT" --dbname "$DATABASE" -tAc "SELECT 1 FROM pg_database WHERE datname = '$DATABASE_TO_CREATE';")

      if [ "$DB_EXISTS" != "1" ]; then
        echo "Creating database '$DATABASE_TO_CREATE'..."
        psql --host "$HOST" --username "$ADMIN_USERNAME" --port "$DATABASE_PORT" --dbname "$DATABASE" -c "CREATE DATABASE "$DATABASE_TO_CREATE";"
      else
        echo "Database '$DATABASE_TO_CREATE' already exists."
      fi
    EOT
  }
}
