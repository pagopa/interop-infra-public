resource "aws_sqs_queue" "jwt_audit" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  name = format("%s-analytics-jwt-audit-%s", local.project, var.env)

  message_retention_seconds = 1209600 # 14 days
  max_message_size          = 262144  # 256 KB
}

resource "aws_sns_topic_subscription" "sqs_jwt_details_new_s3_object" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  topic_arn            = data.aws_sns_topic.jwt_details_new_s3_object.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.jwt_audit[0].arn
  raw_message_delivery = true
}

resource "aws_sqs_queue_policy" "jwt_audit" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  queue_url = aws_sqs_queue.jwt_audit[0].url
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.jwt_audit[0].arn,
        Condition = {
          ArnLike = {
            "aws:SourceArn" = data.aws_sns_topic.jwt_details_new_s3_object.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue" "alb_logs" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  name = format("%s-analytics-alb-logs-%s", local.project, var.env)

  message_retention_seconds = 1209600 # 14 days
  max_message_size          = 262144  # 256 KB
}

resource "aws_sqs_queue_policy" "alb_logs" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  queue_url = aws_sqs_queue.alb_logs[0].url
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action   = "sqs:SendMessage",
        Resource = aws_sqs_queue.alb_logs[0].arn,
        Condition = {
          ArnLike = {
            "aws:SourceArn" = data.aws_s3_bucket.alb_logs_source.arn
          }
        }
      }
    ]
  })
}

resource "aws_sqs_queue" "application_audit_fallback" {
  count = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? 1 : 0

  name = format("%s-analytics-application-audit-fallback-%s", local.project, var.env)

  message_retention_seconds = 1209600 # 14 days
  max_message_size          = 262144  # 256 KB
}