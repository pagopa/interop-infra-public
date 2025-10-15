module "generated_jwt_details_fallback_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-generated-jwt-details-fallback-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  metric_configuration = [
    {
      name   = "AllObjects"
      filter = []
    }
  ]

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
      id         = "RetentionRule"
      enabled    = true
      expiration = { days : 3650 } # delete after 10 years
      transition = {
        days : 30
        storage_class : "STANDARD_IA"
      }
    }
  ]
}

resource "aws_iam_role" "generated_jwt_details_fallback_replication" {
  name = format("%s-generated-jwt-details-fallback-replication-%s-es1", var.short_name, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "batchoperations.s3.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "ReplicateFallbackToMain"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetReplicationConfiguration",
            "s3:ListBucket"
          ],
          Resource = module.generated_jwt_details_fallback_bucket.s3_bucket_arn
        },
        {
          Effect = "Allow"
          Action = [
            "s3:GetObjectVersionForReplication",
            "s3:GetObjectVersionAcl",
            "s3:GetObjectVersionTagging",
            "s3:GetObjectRetention",
            "s3:GetObjectLegalHold"
          ],
          Resource = format("%s/*", module.generated_jwt_details_fallback_bucket.s3_bucket_arn)
        },
        {
          Effect = "Allow"
          Action = [
            "s3:ReplicateObject",
            "s3:ReplicateDelete",
            "s3:ReplicateTags"
          ],
          Resource = format("%s/*", module.generated_jwt_details_bucket.s3_bucket_arn)
        }
      ]
    })
  }

  inline_policy {
    name = "ManualBatchReplication"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "s3:InitiateReplication"
          Resource = format("%s/*", module.generated_jwt_details_fallback_bucket.s3_bucket_arn)
        },
        {
          Effect   = "Allow"
          Action   = "s3:PutInventoryConfiguration"
          Resource = module.generated_jwt_details_fallback_bucket.s3_bucket_arn
        },
        {
          Effect   = "Allow"
          Action   = "s3:PutObject"
          Resource = format("%s/*", module.s3_batch_reports_bucket.s3_bucket_arn)
        }
      ]
    })
  }
}

resource "aws_s3_bucket_replication_configuration" "generated_jwt_details_fallback" {
  bucket = module.generated_jwt_details_fallback_bucket.s3_bucket_id
  role   = aws_iam_role.generated_jwt_details_fallback_replication.arn

  rule {
    id = "ReplicateToMainBucket"

    status = "Enabled"

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Disabled"
    }

    destination {
      bucket        = module.generated_jwt_details_bucket.s3_bucket_arn
      storage_class = "STANDARD"


      replication_time {
        status = "Enabled"

        time {
          minutes = 15
        }
      }

      metrics {
        status = "Enabled"

        event_threshold {
          minutes = 15
        }
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "generated_jwt_fallback_write_activity" {
  alarm_name        = format("generated-jwt-fallback-write-activity-%s", var.env)
  alarm_description = format("Write activity on %s bucket", module.generated_jwt_details_fallback_bucket.s3_bucket_id)

  alarm_actions = [aws_sns_topic.platform_alarms.arn]

  namespace   = "AWS/S3"
  metric_name = "PutRequests"

  dimensions = {
    BucketName = module.generated_jwt_details_fallback_bucket.s3_bucket_id
    FilterId   = "AllObjects"
  }

  comparison_operator = "GreaterThanThreshold"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  threshold           = 0
  period              = 60 # 1 minute
  evaluation_periods  = 30
  datapoints_to_alarm = 1
}

resource "aws_cloudwatch_metric_alarm" "generated_jwt_fallback_replication_failed" {
  alarm_name        = format("generated-jwt-fallback-replication-failed-%s", var.env)
  alarm_description = "Object replication errors from fallback bucket to main bucket"

  alarm_actions = [aws_sns_topic.platform_alarms.arn]

  namespace   = "AWS/S3"
  metric_name = "OperationsFailedReplication"

  dimensions = {
    SourceBucket      = module.generated_jwt_details_fallback_bucket.s3_bucket_id
    RuleId            = aws_s3_bucket_replication_configuration.generated_jwt_details_fallback.rule[0].id
    DestinationBucket = module.generated_jwt_details_bucket.s3_bucket_id
  }

  comparison_operator = "GreaterThanThreshold"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  threshold           = 0
  period              = 60 # 1 minute
  evaluation_periods  = 30
  datapoints_to_alarm = 1
}
