data "aws_subnets" "read_model" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = toset(local.docdb_read_model_cidrs)
  }
}

resource "aws_kms_key" "read_model" {
  description              = format("documentdb/%s-read-model-%s", var.short_name, var.env)
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_secretsmanager_secret" "read_model_master" {
  name        = format("documentdb/%s-read-model-%s/users/%s", var.short_name, var.env, var.read_model_master_username)
  description = "Read Model DB master user credentials"
}

data "aws_secretsmanager_random_password" "read_model" {
  password_length            = 30
  exclude_characters         = "\"@/\\"
  require_each_included_type = true
}

# TODO: rename after migration
resource "aws_secretsmanager_secret_version" "read_model_credentials" {
  secret_id = aws_secretsmanager_secret.read_model_master.id
  secret_string = jsonencode({
    username = var.read_model_master_username
    password = data.aws_secretsmanager_random_password.read_model.random_password
  })

  # TODO: handle rotation
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_docdb_subnet_group" "read_model" {
  name       = format("%s-read-model-%s", var.short_name, var.env)
  subnet_ids = data.aws_subnets.read_model.ids
}

resource "aws_security_group" "read_model" {
  name   = format("documentdb/%s-read-model-%s", var.short_name, var.env)
  vpc_id = module.vpc.vpc_id

  ingress {
    description     = "Access from EKS"
    protocol        = "tcp"
    from_port       = var.read_model_db_port
    to_port         = var.read_model_db_port
    security_groups = [module.eks.cluster_primary_security_group_id]
  }

  ingress {
    description     = "Access from Github Runners"
    protocol        = "tcp"
    from_port       = var.read_model_db_port
    to_port         = var.read_model_db_port
    security_groups = [aws_security_group.github_runners.id]
  }

  ingress {
    description     = "Access from VPN clients"
    protocol        = "tcp"
    from_port       = var.read_model_db_port
    to_port         = var.read_model_db_port
    security_groups = [aws_security_group.vpn_clients.id]
  }
}

resource "aws_docdb_cluster_parameter_group" "read_model" {
  family = var.read_model_parameter_group_family[var.read_model_engine_version]
  name   = format("%s-read-model-%s", var.short_name, var.env)

  parameter {
    name  = "audit_logs"
    value = "enabled"
  }

  parameter {
    name  = "tls"
    value = "disabled"
  }
}

resource "random_id" "read_model_final_snapshot_id" {
  # TODO: is it necessary?
  # keepers = {
  #   id = var.read_model_cluster_id
  # }

  byte_length = 4
}

resource "aws_docdb_cluster" "read_model" {
  cluster_identifier = format("%s-read-model-%s", var.short_name, var.env)
  engine             = "docdb"
  engine_version     = var.read_model_engine_version
  port               = var.read_model_db_port

  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.read_model.name
  db_subnet_group_name            = aws_docdb_subnet_group.read_model.name
  vpc_security_group_ids          = [aws_security_group.read_model.id]
  availability_zones              = module.vpc.azs

  master_username = jsondecode(aws_secretsmanager_secret_version.read_model_credentials.secret_string).username
  master_password = jsondecode(aws_secretsmanager_secret_version.read_model_credentials.secret_string).password

  storage_encrypted = true
  kms_key_id        = aws_kms_key.read_model.arn

  backup_retention_period   = var.env == "prod" ? 30 : 7
  preferred_backup_window   = "02:00-03:00"
  skip_final_snapshot       = false
  final_snapshot_identifier = format("read-model-%s", random_id.read_model_final_snapshot_id.hex)
  deletion_protection       = true

  enabled_cloudwatch_logs_exports = ["audit"]
}

resource "aws_docdb_cluster_instance" "read_model" {
  count = var.read_model_number_instances

  identifier                  = format("read-model-%d", count.index + 1)
  cluster_identifier          = aws_docdb_cluster.read_model.id
  availability_zone           = element(module.vpc.azs, count.index)
  instance_class              = var.read_model_instance_class
  ca_cert_identifier          = var.read_model_ca_cert_id
  enable_performance_insights = true

  apply_immediately = true

  lifecycle {
    create_before_destroy = true
  }
}
