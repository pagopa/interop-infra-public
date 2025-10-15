moved {
  from = aws_sns_topic.on_call_opsgenie
  to   = aws_sns_topic.on_call_opsgenie[0]
}

resource "aws_sns_topic" "on_call_opsgenie" {
  count = local.on_call_env ? 1 : 0

  name = "Opsgenie"
}

moved {
  from = aws_sns_topic.on_call_cw_alarms
  to   = aws_sns_topic.on_call_cw_alarms[0]
}

resource "aws_sns_topic_policy" "on_call_cw_alarms" {
  count = local.on_call_env ? 1 : 0

  arn = aws_sns_topic.on_call_opsgenie[0].arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.on_call_opsgenie[0].arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:cloudwatch:${var.aws_region}:${data.aws_caller_identity.current.account_id}:alarm:*"
          }
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}
