resource "aws_glue_job" "jwt_audit_etl_csv" {
  name              = format("%s-analytics-jwt-audit-etl-csv-%s", local.project, var.env)
  description       = "JWT audit ETL CSV"
  role_arn          = aws_iam_role.jwt_audit_etl[0].arn
  glue_version      = "4.0"
  max_retries       = 0
  timeout           = 300 # minutes
  number_of_workers = 6   # 1 worker is reserved to Spark Driver
  worker_type       = "G.2X"
  execution_class   = "STANDARD"

  command {
    script_location = "s3://${module.glue_spark_assets_bucket[0].s3_bucket_id}/scripts/jwt_audit_etl_csv.py"
    name            = "glueetl"
    python_version  = "3"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--continuous-log-logGroup"          = format("/aws-glue/jobs/%s-analytics-jwt-etl-csv-%s", local.project, var.env)
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-spark-ui"                  = "true"
    "--enable-job-insights"              = "true"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--TempDir"                          = "s3://${module.glue_spark_assets_bucket[0].s3_bucket_id}/temporary"
    "--spark-event-logs-path"            = "s3://${module.glue_spark_assets_bucket[0].s3_bucket_id}/spark-event-logs/"
    "--SOURCE_BUCKET"                    = data.aws_s3_bucket.jwt_audit_source.id
    "--SOURCE_PREFIX"                    = "token-details/2022*"
    "--DESTINATION_BUCKET"               = module.glue_spark_outputs_bucket[0].s3_bucket_id
    "--DESTINATION_PREFIX"               = "jwt-audit-etl-csv/2022"
  }

}

resource "aws_s3_object" "jwt_audit_etl_csv_script" {
  count = local.deploy_spark_etl_jobs ? 1 : 0

  bucket = module.glue_spark_assets_bucket[0].s3_bucket_id
  key    = "scripts/jwt_audit_etl_csv.py"

  source      = "${path.module}/glue-spark/jwt_audit_etl_csv.py"
  source_hash = filesha256("${path.module}/glue-spark/jwt_audit_etl_csv.py")
}
