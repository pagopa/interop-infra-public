resource "aws_quicksight_data_set" "auth_server_calls_prevision_data" {
  count = local.deploy_redshift_cluster ? 1 : 0

  data_set_id = format("%s-%s-auth-server-calls-prevision-data", local.project, var.env)
  import_mode = "SPICE"
  name        = format("Auth Server Calls Prevision Data (%s-%s)", local.project, var.env)

  data_set_usage_configuration {
    disable_use_as_direct_query_source = false
    disable_use_as_imported_source     = false
  }

  refresh_properties {
    refresh_configuration {
      incremental_refresh {
        lookback_window {
          column_name = "date_slot"
          size_unit   = "DAY"
          size        = 5
        }
      }
    }
  }

  physical_table_map {
    physical_table_map_id = replace(title(format("%s %s auth server calls prevision data", local.project, var.env)), " ", "")

    custom_sql {
      name            = format("Query on %s-%s.views.mv_00_auth_usage__data__calls", local.project, var.env)
      data_source_arn = aws_quicksight_data_source.analytics_views[0].arn
      sql_query       = file("${path.module}/60-qs-dashboard-auth-server-prevision-data-set.sql")

      columns {
        name = "today_severity"
        type = "INTEGER"
      }
      columns {
        name = "consumer_name"
        type = "STRING"
      }
      columns {
        name = "client_name"
        type = "STRING"
      }
      columns {
        name = "date_slot"
        type = "DATETIME"
      }
      columns {
        name = "max_limit"
        type = "INTEGER"
      }
      columns {
        name = "calls_by_day"
        type = "INTEGER"
      }
      columns {
        name = "status"
        type = "STRING"
      }
      columns {
        name = "status_severity"
        type = "INTEGER"
      }
    }
  }

  logical_table_map {
    logical_table_map_id = replace(
      title(format("%s-%s-auth-server-calls-with-prevision-LTM", local.project, var.env)),
      "-",
      ""
    )
    alias = format("%s-%s.views.mv_00_auth_svc_calls_with_expect", local.project, var.env)

    data_transforms {
      project_operation {
        projected_columns = [
          "today_severity",
          "consumer_name",
          "client_name",
          "date_slot",
          "max_limit",
          "calls_by_day",
          "status",
          "status_severity"
        ]
      }
    }
    source {
      physical_table_id = replace(title(format("%s %s auth server calls prevision data", local.project, var.env)), " ", "")
    }
  }

  permissions {
    principal = "${local.quicksight_groups_arn_prefix}-quicksight-admins"
    actions   = local.quicksight_data_set_read_write_actions
  }
  permissions {
    principal = "${local.quicksight_groups_arn_prefix}-quicksight-authors"
    actions   = local.quicksight_data_set_read_only_actions
  }

  tags = {
    "RefreshType" = "INCREMENTAL_REFRESH"
  }

}


# Dashboard definition
module "dashboard_auth_server_calls_prevision_violation" {
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

  dashboard_id                   = format("%s-%s-auth_server_calls_with_prevision_violations_DASH", local.project, var.env)
  dashboard_name                 = format("Auth server clients Calls Prevision and Violations (Preview %s-%s)", local.project, var.env)
  dashboard_definition_file_path = "${path.module}/quicksight-json-dashboards/60-qs-dashboard-auth-server-prevision-dashboard.json"

  database_name = format("%s-%s", local.project, var.env)
  data_sets_arns = [
    {
      identifier   = "New custom SQL"
      data_set_arn = aws_quicksight_data_set.auth_server_calls_prevision_data[0].arn
    }
  ]

  dashboard_permissions = local.default_dashboard_permissions

}


