resource "aws_sns_topic" "logs_automation_errors" {
  name = format("%s-logs-automation-errors-%s", var.short_name, var.env)
}

resource "aws_sns_topic_policy" "logs_automation_errors" {
  arn = aws_sns_topic.logs_automation_errors.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.logs_automation_errors.arn
      }
    ]
  })
}

resource "aws_sns_topic" "platform_alarms" {
  name = format("%s-platform-alarms-%s", var.short_name, var.env)
}

resource "aws_sns_topic_policy" "platform_alarms" {
  arn = aws_sns_topic.platform_alarms.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.platform_alarms.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:*"
          }
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.platform_alarms.arn
      }
    ]
  })
}

resource "aws_sns_topic" "ses_reputation" {
  name = format("%s-ses-reputation-%s", var.short_name, var.env)
}

resource "aws_sns_topic_policy" "ses_reputation" {
  arn = aws_sns_topic.ses_reputation.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.ses_reputation.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:*"
          }
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowEventBridge"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.ses_reputation.arn
      }
    ]
  })
}

resource "aws_sns_topic" "jwt_details_new_s3_object" {
  name = format("%s-jwt-details-new-s3-object-%s", local.project, var.env)
}

resource "aws_sns_topic_policy" "jwt_details_new_s3_object" {
  arn = aws_sns_topic.jwt_details_new_s3_object.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3EventsPublish"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.jwt_details_new_s3_object.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = module.generated_jwt_details_bucket.s3_bucket_arn
          }
        }
      }
    ]
  })
}
