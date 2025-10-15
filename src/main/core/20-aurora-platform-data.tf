data "aws_subnets" "aurora_platform_data" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = toset(local.aurora_platform_data_cidrs)
  }
}

resource "aws_kms_key" "platform_data" {
  description              = format("rds/%s-platform-data-%s", var.short_name, var.env)
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

locals {
  platform_data_common_parameters = [
    {
      name  = "rds.force_ssl"
      value = 1
    }
  ]
  # TODO: temporary, refactor/remove
  platform_data_parameters = (local.deploy_be_refactor_infra
    ? concat(local.platform_data_common_parameters, [{ name = "rds.logical_replication", value = 1, apply_method = "pending-reboot" }])
  : local.platform_data_common_parameters)
}

module "platform_data" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.15.0"

  name                = format("%s-platform-data-%s", var.short_name, var.env)
  deletion_protection = true
  apply_immediately   = true

  auto_minor_version_upgrade = false

  database_name                        = var.platform_data_database_name
  master_username                      = var.platform_data_master_username
  manage_master_user_password          = true
  manage_master_user_password_rotation = false

  engine             = "aurora-postgresql"
  engine_version     = var.platform_data_engine_version
  instance_class     = var.platform_data_instance_class
  ca_cert_identifier = var.platform_data_ca_cert_id

  instances_use_identifier_prefix = false
  instances = { for n in range(var.platform_data_number_instances) : "instance-${n + 1}" =>
    {
      identifier        = format("platform-data-%d", n + 1)
      availability_zone = element(module.vpc.azs, n)
  } }

  create_db_cluster_parameter_group          = true
  db_cluster_parameter_group_use_name_prefix = false
  db_cluster_parameter_group_name            = format("%s-platform-data-%s", var.short_name, var.env)
  db_cluster_parameter_group_family          = var.platform_data_parameter_group_family
  db_cluster_parameter_group_parameters      = local.platform_data_parameters

  vpc_id             = module.vpc.vpc_id
  subnets            = data.aws_subnets.aurora_platform_data.ids
  availability_zones = module.vpc.azs

  create_db_subnet_group = true
  db_subnet_group_name   = format("%s-platform-data-%s", var.short_name, var.env)

  create_security_group          = true
  security_group_use_name_prefix = false
  security_group_name            = format("rds/%s-platform-data-%s", var.short_name, var.env)

  security_group_rules = {
    from_eks_cluster = {
      type                     = "ingress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = module.eks.cluster_primary_security_group_id
    }

    from_github_runners = {
      type                     = "ingress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.github_runners.id
    }

    from_vpn_clients = {
      type                     = "ingress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.vpn_clients.id
    }
  }

  storage_encrypted         = true
  kms_key_id                = aws_kms_key.platform_data.arn
  backup_retention_period   = var.env == "prod" ? 30 : 7
  skip_final_snapshot       = var.env == "dev" || var.env == "qa"
  final_snapshot_identifier = format("%s-platform-data-%s-final", var.short_name, var.env)

  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["postgresql"]
  cloudwatch_log_group_retention_in_days = var.env == "prod" ? 180 : 30

  create_monitoring_role                = true
  iam_role_name                         = format("%s-platform-data-enhanced-monitoring-%s", var.short_name, var.env)
  performance_insights_enabled          = true
  performance_insights_retention_period = var.env == "prod" ? 372 : 7
  monitoring_interval                   = 60
  performance_insights_kms_key_id       = aws_kms_key.platform_data.arn
}

# Workaround
resource "null_resource" "disable_secret_rotation" {
  depends_on = [module.platform_data]

  triggers = {
    secret_arn = module.platform_data.cluster_master_user_secret[0].secret_arn
  }

  provisioner "local-exec" {
    on_failure = fail
    command    = "aws secretsmanager cancel-rotate-secret --region ${var.aws_region} --secret-id ${module.platform_data.cluster_master_user_secret[0].secret_arn}"
  }
}
