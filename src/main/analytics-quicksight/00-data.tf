
data "aws_vpc" "core" {
  id = var.vpc_id
}

data "aws_sns_topic" "analytics_alarms" {
  name = var.analytics_alarms_topic_name
}

data "aws_security_group" "quicksight_analytic" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name   = var.quicksight_analytics_security_group_name
  vpc_id = data.aws_vpc.core.id
}

data "aws_subnets" "analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  filter {
    name   = "subnet-id"
    values = var.analytics_subnet_ids
  }
}

data "aws_secretsmanager_secret_version" "quicksight_user_secret_version" {
  count = local.deploy_redshift_cluster ? 1 : 0

  secret_id = var.quicksight_redshift_user_credential_secret
}

data "aws_redshift_cluster" "analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  cluster_identifier = var.redshift_cluster_identifier
}

data "aws_sns_topic" "redshift_events" {
  count = local.deploy_datasets_schedule_lambda ? 1 : 0

  name = var.redshift_maintenance_events_topic_name
}
