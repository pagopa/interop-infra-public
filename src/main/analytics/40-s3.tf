resource "aws_s3_bucket_notification" "alb_logs_source" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  depends_on = [aws_sqs_queue_policy.alb_logs[0]]

  bucket = data.aws_s3_bucket.alb_logs_source.id

  queue {
    queue_arn = aws_sqs_queue.alb_logs[0].arn
    events    = ["s3:ObjectCreated:Put"]
  }
}

module "application_audit_archive" {
  count = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  bucket = format("%s-application-audit-archive-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode  = var.env == "prod" ? "COMPLIANCE" : "GOVERNANCE"
        years = 10
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "StandardIARule"
      enabled = true
      transition = {
        days : 30
        storage_class : "STANDARD_IA"
      }
    }
  ]
}

module "glue_spark_assets_bucket" {
  count = local.deploy_spark_etl_jobs ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  bucket = format("%s-analytics-glue-spark-assets-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "glue_spark_outputs_bucket" {
  count = local.deploy_spark_etl_jobs ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  bucket = format("%s-analytics-glue-spark-outputs-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}
