
# It is not possible to use INCREMENTAL_REFRESH because this dataset (and the underlying view)
# does not have a time column that reflects the record's last modification timestamp;
# this dataset does not have meaningful alarms and needs data to be as fresh as possible. 
# For those reasons we keep DIRECT_QUERY as import_mode for this data set.
resource "aws_quicksight_data_set" "tenants_clients_access_by_ip" {
  count = local.deploy_redshift_cluster ? 1 : 0

  data_set_id = format("%s-%s-tenants_clients_access_by_ip", local.project, var.env)
  import_mode = "DIRECT_QUERY"
  name        = format("Tenants Clients access by IP (%s-%s)", local.project, var.env)

  data_set_usage_configuration {
    disable_use_as_direct_query_source = false
    disable_use_as_imported_source     = false
  }

  physical_table_map {
    physical_table_map_id = replace(title(format("%s %s tenants clients access by ip ptm", local.project, var.env)), " ", "")

    custom_sql {
      name            = format("Query on %s-%s.views.mv_01_client_tenant_authserver_ips", local.project, var.env)
      data_source_arn = aws_quicksight_data_source.analytics_views[0].arn
      sql_query       = <<-EOT
        WITH 
          splitted_ips AS (
            SELECT
              tenant_name,
              client_name,
              split_to_array(ips) as ips,
              timestamp 'epoch' + (latest_ts / 1000) * interval '1 second' as latest_ts,
              timestamp 'epoch' + (oldest_ts / 1000) * interval '1 second' as oldest_ts
            FROM
              views.mv_01_client_tenant_authserver_ips
          )
        SELECT
          si.tenant_name,
          si.client_name,
          trim(cast(si_el as varchar)) ip,
          si.latest_ts,
          si.oldest_ts
        FROM
          splitted_ips si
          JOIN si.ips si_el ON TRUE
        WHERE
          NOT trim(cast(si_el as varchar)) LIKE '10.%'
      EOT

      columns {
        name = "tenant_name"
        type = "STRING"
      }
      columns {
        name = "client_name"
        type = "STRING"
      }
      columns {
        name = "ip"
        type = "STRING"
      }
      columns {
        name = "latest_ts"
        type = "DATETIME"
      }
      columns {
        name = "oldest_ts"
        type = "DATETIME"
      }
    }
  }

  logical_table_map {
    logical_table_map_id = replace(
      title(format("%s-%s-tenants-clients-access-by-ip-LTM", local.project, var.env)),
      "-",
      ""
    )
    alias = format("%s-%s.views.mv_01_client_tenant_authserver_single_ip", local.project, var.env)

    data_transforms {
      project_operation {
        projected_columns = [
          "tenant_name",
          "client_name",
          "ip",
          "latest_ts",
          "oldest_ts"
        ]
      }
    }
    source {
      physical_table_id = replace(title(format("%s %s tenants clients access by ip ptm", local.project, var.env)), " ", "")
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

}


# Dashboard definition
module "dashboard_tenants_clients_access_by_ip" {
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

  dashboard_id                   = format("%s-%s-tenants_clients_access_by_ip_DASH", local.project, var.env)
  dashboard_name                 = format("Clients IPs (%s-%s)", local.project, var.env)
  dashboard_definition_file_path = "${path.module}/quicksight-json-dashboards/dashboard-clients-ips-usage.json"

  database_name = format("%s-%s", local.project, var.env)
  data_sets_arns = [
    {
      identifier   = "analysis__tenants_clients_access_by_ip_ds"
      data_set_arn = aws_quicksight_data_set.tenants_clients_access_by_ip[0].arn
    }
  ]

  dashboard_permissions = local.default_dashboard_permissions
}
