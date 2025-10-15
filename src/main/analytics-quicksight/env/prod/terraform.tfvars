aws_region = "eu-south-1"
env        = "prod"

tags = {
  CreatedBy   = "Terraform"
  Environment = "prod"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-infra"
}

vpc_id               = ""
analytics_subnet_ids = []

quicksight_identity_center_arn    = ""
quicksight_identity_center_region = ""

quicksight_notification_email = ""

quicksight_analytics_security_group_name   = "quicksight/interop-analytics-prod"
quicksight_redshift_user_credential_secret = "redshift/interop-analytics-prod/users/prod_quicksight_user"
redshift_cluster_identifier                = "interop-analytics-prod"
analytics_alarms_topic_name                = "interop-analytics-alarms-prod"
redshift_maintenance_events_topic_name     = "interop-analytics-redshift-events-prod"

quicksight_datasets_schedule_lambda = {
  zip_url        = "https://github.com/pagopa/interop-infra-lambdas/releases/download/v1.2.0/quicksight-alert-scheduling-on-off.zip"
  zip_sha256_hex = "fd0db388f5715b31ab946018dc8a6f22b4317cc8650cc4a80e46b75dfb52262f"
}
