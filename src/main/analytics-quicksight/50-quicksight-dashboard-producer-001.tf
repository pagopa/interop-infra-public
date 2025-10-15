# This dataset does not have a column with record's insert timestamp.
# The "last_issued_at_ts" column is a record modification timestamp that 
# can generate duplicates and need a periodic full refresh. Currently a 
# dataset can have only one schedule.
module "data_set_views_mv_01_eservice_not_used_after_ts__last_issued_at" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  spice_config = {
    use_spice        = true
    refresh_type     = "FULL_REFRESH"
    refresh_interval = "HOURLY"
  }

  view_name = "mv_01_eservice_not_used_after_ts__last_issued_at"
  columns = [
    {
      name = "producer_name"
      type = "STRING"
    },
    {
      name = "eservice_id"
      type = "STRING"
    },
    {
      name = "eservice_name"
      type = "STRING"
    },
    {
      name = "last_issued_at"
      type = "INTEGER"
    },
    {
      name = "last_issued_at_ts"
      type = "DATETIME"
    }
  ]

  data_set_permissions = local.default_data_set_permissions
}

# INCREMENTAL_REFRESH is not possible because this dataset does not have a column 
# with record's insert timestamp.
module "data_set_views_mv_02_eservice_without_token__final" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  spice_config = {
    use_spice        = true
    refresh_type     = "FULL_REFRESH"
    refresh_interval = "HOURLY"
  }

  view_name = "mv_02_eservice_without_token__final"
  columns = [
    {
      name = "producer_name"
      type = "STRING"
    },
    {
      name = "exposed_eservice__count"
      type = "INTEGER"
    },
    {
      name = "eservice_not_used_by_others__count"
      type = "INTEGER"
    },
    {
      name = "eservice_not_used_by_others__percent"
      type = "DECIMAL"
    }
  ]

  data_set_permissions = local.default_data_set_permissions
}

# INCREMENTAL_REFRESH is not possible because this dataset does not have a column 
# with record's insert timestamp.
module "data_set_views_mv_01_daily_calls_overbooking__by_eservice_and_consumer" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  spice_config = {
    use_spice        = true
    refresh_type     = "FULL_REFRESH"
    refresh_interval = "HOURLY"
  }

  view_name = "mv_01_daily_calls_overbooking__by_eservice_and_consumer"
  columns = [
    {
      name = "producer_name"
      type = "STRING"
    },
    {
      name = "eservice_id"
      type = "STRING"
    },
    {
      name = "consumer_name"
      type = "STRING"
    },
    {
      name = "eservice_name"
      type = "STRING"
    },
    {
      name = "eservice_declared_daily_calls_total"
      type = "INTEGER"
    },
    {
      name = "eservice_declared_calls_per_consumer"
      type = "INTEGER"
    },
    {
      name = "consumers_declared_daily_calls_sum"
      type = "INTEGER"
    },
    {
      name = "consumer_booked_percentage"
      type = "DECIMAL"
    }
  ]

  data_set_permissions = local.default_data_set_permissions
}

# INCREMENTAL_REFRESH is not possible because this dataset does not have a column 
# with record's insert timestamp.
module "data_set_views_mv_01_daily_calls_overbooking__by_eservice" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  spice_config = {
    use_spice        = true
    refresh_type     = "FULL_REFRESH"
    refresh_interval = "HOURLY"
  }

  view_name = "mv_01_daily_calls_overbooking__by_eservice"
  columns = [
    {
      name = "producer_name"
      type = "STRING"
    },
    {
      name = "eservice_id"
      type = "STRING"
    },
    {
      name = "eservice_name"
      type = "STRING"
    },
    {
      name = "eservice_declared_daily_calls_total"
      type = "INTEGER"
    },
    {
      name = "consumers_declared_daily_calls_sum"
      type = "INTEGER"
    },
    {
      name = "total_booked_percentage"
      type = "DECIMAL"
    }
  ]

  data_set_permissions = local.default_data_set_permissions

}

# INCREMENTAL_REFRESH is not possible because this dataset does not have a column 
# with record's insert timestamp.
module "data_set_views_mv_01_avg_first_token_delta_by_eservice__final" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  spice_config = {
    use_spice        = true
    refresh_type     = "FULL_REFRESH"
    refresh_interval = "HOURLY"
  }

  view_name = "mv_01_avg_first_token_delta_by_eservice__final"
  columns = [
    {
      name = "producer_name"
      type = "STRING"
    },
    {
      name = "eservice_id"
      type = "STRING"
    },
    {
      name = "avg_first_token_delta_time__seconds"
      type = "INTEGER"
    },
    {
      name = "num_of_agreement"
      type = "INTEGER"
    }
  ]

  data_set_permissions = local.default_data_set_permissions
}


# Dashboard definition
module "dashboard_producer_perspective_001" {
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

  dashboard_id                   = format("%s-%s-producer_perspective_001_DASH", local.project, var.env)
  dashboard_name                 = format("Producer Perspective 001 (%s-%s)", local.project, var.env)
  dashboard_definition_file_path = "${path.module}/quicksight-json-dashboards/dashboard-producer-perspective-001.json"

  database_name = format("%s-%s", local.project, var.env)
  data_sets_arns = [
    {
      identifier   = "mv_01_daily_calls_overbooking__by_eservice"
      data_set_arn = module.data_set_views_mv_01_daily_calls_overbooking__by_eservice[0].data_set_arn
    },
    {
      identifier   = "mv_01_avg_first_token_delta_by_eservice__final"
      data_set_arn = module.data_set_views_mv_01_avg_first_token_delta_by_eservice__final[0].data_set_arn
    },
    {
      identifier   = "mv_01_eservice_not_used_after_ts__last_issued_at"
      data_set_arn = module.data_set_views_mv_01_eservice_not_used_after_ts__last_issued_at[0].data_set_arn
    },
    {
      identifier   = "mv_01_daily_calls_overbooking__by_eservice_and_consumer"
      data_set_arn = module.data_set_views_mv_01_daily_calls_overbooking__by_eservice_and_consumer[0].data_set_arn
    },
    {
      identifier   = "mv_02_eservice_without_token__final"
      data_set_arn = module.data_set_views_mv_02_eservice_without_token__final[0].data_set_arn
    }
  ]

  dashboard_permissions = local.default_dashboard_permissions

}
