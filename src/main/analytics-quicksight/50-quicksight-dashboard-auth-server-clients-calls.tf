# Keep direct query to have data updated every 5 minutes
module "data_set_views_mv_01_auth_usage__data__last_calls" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  view_name = "mv_01_auth_usage__data__last_calls"
  columns = [
    {
      name = "consumer_name"
      type = "STRING"
    },
    {
      name = "client_name"
      type = "STRING"
    },
    {
      name = "calls_quantity"
      type = "INTEGER"
    },
    {
      name = "total_execution_time"
      type = "INTEGER"
    },
    {
      name = "quantity_2xx"
      type = "INTEGER"
    },
    {
      name = "total_2xx_execution_time"
      type = "INTEGER"
    },
    {
      name = "quantity_4xx"
      type = "INTEGER"
    },
    {
      name = "total_4xx_execution_time"
      type = "INTEGER"
    },
    {
      name = "quantity_5xx"
      type = "INTEGER"
    },
    {
      name = "from_ts"
      type = "DATETIME"
    },
    {
      name = "to_ts"
      type = "DATETIME"
    },
    {
      name = "period_length_minutes"
      type = "INTEGER"
    }
  ]

  data_set_permissions = local.default_data_set_permissions
}

# It is fine for incremental refresh every 15 minutes.
# Keep 5 days log refresh window to handle weekend and late data ingestion.
module "data_set_views_mv_00_auth_usage__data__calls" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  spice_config = {
    use_spice        = true
    refresh_type     = "INCREMENTAL_REFRESH"
    refresh_interval = "MINUTE15"
    incremental_refresh_properties = {
      column_name = "minute_slot"
      size_unit   = "DAY"
      size        = 5
    }
  }

  view_name = "mv_00_auth_usage__data__calls"
  columns = [
    {
      name = "epoch_of_the_second_when_the_minute_slot_is_started"
      type = "INTEGER"
    },
    {
      name = "minute_slot"
      type = "DATETIME"
    },
    {
      name = "consumer_name"
      type = "STRING"
    },
    {
      name = "client_name"
      type = "STRING"
    },
    {
      name = "calls_quantity"
      type = "INTEGER"
    },
    {
      name = "total_execution_time"
      type = "INTEGER"
    },
    {
      name = "quantity_2xx"
      type = "INTEGER"
    },
    {
      name = "total_2xx_execution_time"
      type = "INTEGER"
    },
    {
      name = "quantity_4xx"
      type = "INTEGER"
    },
    {
      name = "total_4xx_execution_time"
      type = "INTEGER"
    },
    {
      name = "quantity_5xx"
      type = "INTEGER"
    }
  ]

  data_set_permissions = local.default_data_set_permissions
}

# Dashboard definition
module "dashboard_auth_server_client_calls" {
  source = "./modules/quicksight-dashboard-from-json"
  count  = local.deploy_redshift_cluster ? 1 : 0

  # The deleted field is introduced because the module use "destroy time provisioner" and, as documentation report,
  # https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax#destroy-time-provisioners
  # if the module is commented the destroy provisioner is not executed. The documentation suggest the following steps:
  #  - Update the resource configuration to include count = 0.
  #  - Apply the configuration to destroy any existing instances of the resource, including running the destroy provisioner.
  #  - Remove the resource block entirely from configuration, along with its provisioner blocks.
  #  - Apply again, at which point no further action should be taken since the resources were already destroyed.
  # Step to delete a dashboard:
  #  - set the following "deleted" field to true without any other change. 
  #  - release into all environment
  #  - after some month delete the module usage from the terraform file.
  #deleted = false

  dashboard_id                   = format("%s-%s-auth_server_client_calls_DASH", local.project, var.env)
  dashboard_name                 = format("Auth server clients Calls (%s-%s)", local.project, var.env)
  dashboard_definition_file_path = "${path.module}/quicksight-json-dashboards/dashboard-auth-server-client-calls.json"

  database_name = format("%s-%s", local.project, var.env)
  data_sets_arns = [
    {
      identifier   = "mv_01_auth_usage__data__last_calls"
      data_set_arn = module.data_set_views_mv_01_auth_usage__data__last_calls[0].data_set_arn
    },
    {
      identifier   = "mv_00_auth_usage__data__calls"
      data_set_arn = module.data_set_views_mv_00_auth_usage__data__calls[0].data_set_arn
    }
  ]

  dashboard_permissions = local.default_dashboard_permissions
}
