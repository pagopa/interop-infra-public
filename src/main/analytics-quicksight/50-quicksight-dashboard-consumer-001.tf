# INCREMENTAL_REFRESH is not possible because this dataset does not have a column 
# with record's insert timestamp.
module "data_set_views_mv_02_not_used_subscribed_eservice__final" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  spice_config = {
    use_spice        = true
    refresh_type     = "FULL_REFRESH"
    refresh_interval = "HOURLY"
  }

  view_name = "mv_02_not_used_subscribed_eservice__final"
  columns = [
    {
      name = "consumer_name"
      type = "STRING"
    },
    {
      name = "used_eservices"
      type = "INTEGER"
    },
    {
      name = "subscribed_eservices"
      type = "INTEGER"
    },
    {
      name = "used_eservices_percent"
      type = "DECIMAL"
    },
    {
      name = "unused_eservice"
      type = "INTEGER"
      computed = {
        expression = "{subscribed_eservices} - {used_eservices}"
      }
    }
  ]

  data_set_permissions = local.default_data_set_permissions
}

# INCREMENTAL_REFRESH is not possible because this dataset does not have a column 
# with record's insert timestamp.
module "data_set_views_mv_02_client_without_token__final" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  spice_config = {
    use_spice        = true
    refresh_type     = "FULL_REFRESH"
    refresh_interval = "HOURLY"
  }

  view_name = "mv_02_client_without_token__final"
  columns = [
    {
      name = "consumer_name"
      type = "STRING"
    },
    {
      name = "client__count"
      type = "INTEGER"
    },
    {
      name = "client_not_used__count"
      type = "INTEGER"
    },
    {
      name = "client_not_used__percent"
      type = "DECIMAL"
    }
  ]

  data_set_permissions = local.default_data_set_permissions
}

# This dataset does not have a column with record's insert timestamp.
# The "last_issued_at_ts" column is a record modification timestamp that 
# can generate duplicate and need a periodic full refresh. Currently a 
# dataset can have only one schedule.
module "data_set_views_mv_01_client_not_used_after_ts__last_issued_at" {
  source = "./modules/quicksight-data-set-view-wrapper"
  count  = local.deploy_redshift_cluster ? 1 : 0

  database_name   = format("%s-%s", local.project, var.env)
  data_source_arn = aws_quicksight_data_source.analytics_views[0].arn

  spice_config = {
    use_spice        = true
    refresh_type     = "FULL_REFRESH"
    refresh_interval = "HOURLY"
  }

  view_name = "mv_01_client_not_used_after_ts__last_issued_at"
  columns = [
    {
      name = "consumer_name"
      type = "STRING"
    },
    {
      name = "client_id"
      type = "STRING"
    },
    {
      name = "client_name"
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


# Dashboard definition
module "dashboard_consumer_perspective_001" {
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

  dashboard_id                   = format("%s-%s-consumer_perspective_001_DASH", local.project, var.env)
  dashboard_name                 = format("Consumer Perspective 001 (%s-%s)", local.project, var.env)
  dashboard_definition_file_path = "${path.module}/quicksight-json-dashboards/dashboard-consumer-perspective-001.json"

  database_name = format("%s-%s", local.project, var.env)
  data_sets_arns = [
    {
      identifier   = "mv_02_not_used_subscribed_eservice__final"
      data_set_arn = module.data_set_views_mv_02_not_used_subscribed_eservice__final[0].data_set_arn
    },
    {
      identifier   = "mv_02_client_without_token__final"
      data_set_arn = module.data_set_views_mv_02_client_without_token__final[0].data_set_arn
    },
    {
      identifier   = "mv_01_client_not_used_after_ts__last_issued_at"
      data_set_arn = module.data_set_views_mv_01_client_not_used_after_ts__last_issued_at[0].data_set_arn
    }
  ]

  dashboard_permissions = local.default_dashboard_permissions
}

