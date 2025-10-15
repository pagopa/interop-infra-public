locals {
  # The crawler resource creates a table with the same name as the data source bucket, and replaces - with _
  app_logs_glue_table_name = replace(module.application_logs_bucket.s3_bucket_id, "-", "_")
}

resource "aws_athena_workgroup" "interop_queries" {
  name  = format("interop-queries-%s", var.env)
  state = "ENABLED"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = format("s3://%s", module.athena_query_results_bucket.s3_bucket_id)
    }
  }
}

resource "aws_athena_named_query" "app_logs_errors_fulldate" {
  name        = "app-logs-errors-fulldate"
  workgroup   = aws_athena_workgroup.interop_queries.id
  database    = "default"
  description = "Parameter1=year, Parameter2=month, Parameter3=day"

  query = <<-EOT
    SELECT
      cw_timestamp,
      json_extract_scalar(message, '$.log') AS message
    FROM "${local.app_logs_glue_table_name}"
    WHERE year = CAST(? AS varchar)
    AND month = CAST(? as varchar)
    AND day = CAST(? as varchar)
    AND regexp_like(json_extract_scalar(message, '$.log'), 'ERROR')
    ORDER BY cw_timestamp ASC;
  EOT
}

resource "aws_athena_named_query" "app_logs_cid_fulldate" {
  name        = "app-logs-corr-id-fulldate"
  workgroup   = aws_athena_workgroup.interop_queries.id
  database    = "default"
  description = "Parameter1=year, Parameter2=month, Parameter3=day, Parameter4=CorrelationId"

  query = <<-EOT
    SELECT
      cw_timestamp,
      json_extract_scalar(message, '$.log') AS message
    FROM "${local.app_logs_glue_table_name}"
    WHERE year = CAST(? as varchar)
    AND month = CAST(? as varchar)
    AND day = CAST(? as varchar)
    AND regexp_like(json_extract_scalar(message, '$.log'), concat('CID=', ?))
    ORDER BY cw_timestamp ASC;
  EOT
}

resource "aws_athena_named_query" "app_logs_cid_month" {
  name        = "app-logs-corr-id-month"
  workgroup   = aws_athena_workgroup.interop_queries.id
  database    = "default"
  description = "Parameter1=year, Parameter2=month, Parameter3=CorrelationId"

  query = <<-EOT
    SELECT
      cw_timestamp,
      json_extract_scalar(message, '$.log') AS message
    FROM "${local.app_logs_glue_table_name}"
    WHERE year = CAST(? as varchar)
    AND month = CAST(? as varchar)
    AND regexp_like(json_extract_scalar(message, '$.log'), concat('CID=', ?))
    ORDER BY cw_timestamp ASC;
  EOT
}

resource "aws_athena_named_query" "app_logs_cid_nodate" {
  name        = "app-logs-corr-id-nodate"
  workgroup   = aws_athena_workgroup.interop_queries.id
  database    = "default"
  description = "Parameter1=CorrelationId"

  query = <<-EOT
    SELECT
      cw_timestamp,
      json_extract_scalar(message, '$.log') AS message
    FROM "${local.app_logs_glue_table_name}"
    WHERE regexp_like(json_extract_scalar(message, '$.log'), concat('CID=', ?))
    ORDER BY cw_timestamp ASC;
  EOT
}
