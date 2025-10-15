resource "aws_iam_role" "app_logs_crawler" {
  name = "interop-application-logs-crawler-${var.env}-es1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "glue.amazonaws.com"
          ]
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]
  inline_policy {
    name = "InteropAppLogsGlue"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = "${module.application_logs_bucket.s3_bucket_arn}/*"
        }
      ]
    })
  }
}

resource "aws_glue_classifier" "cw_logs" {
  name = "cw-app-logs"
  grok_classifier {
    classification = "cw-app-logs"
    grok_pattern   = "%%{TIMESTAMP_ISO8601:cw_timestamp}\\s+%%{GREEDYDATA:message}"
  }
}

resource "aws_glue_crawler" "app_logs" {
  name = "app-logs-crawler"
  classifiers = [
    aws_glue_classifier.cw_logs.id
  ]
  database_name = "default"
  recrawl_policy {
    recrawl_behavior = "CRAWL_NEW_FOLDERS_ONLY"
  }
  role = aws_iam_role.app_logs_crawler.arn
  s3_target {
    path = "s3://${module.application_logs_bucket.s3_bucket_id}"
    exclusions = [
      "**/aws-logs-write-test",
      "**/aws-logs-write-test-multipartupload"
    ]
  }
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "LOG"
  }
}
