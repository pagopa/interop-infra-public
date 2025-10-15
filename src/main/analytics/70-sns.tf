resource "aws_sns_topic" "analytics_alarms" {
  name = format("%s-analytics-alarms-%s", local.project, var.env)
}

resource "aws_sns_topic_policy" "analytics_alarms" {
  arn = aws_sns_topic.analytics_alarms.arn

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
        Resource = aws_sns_topic.analytics_alarms.arn
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
        Resource = aws_sns_topic.analytics_alarms.arn
      }
    ]
  })
}

resource "aws_sns_topic" "redshift_events" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name = format("%s-analytics-redshift-events-%s", local.project, var.env)
}

resource "aws_redshift_event_subscription" "redshift_events_sub" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name          = format("%s-redshift-event-subscription-%s", local.project, var.env)
  sns_topic_arn = aws_sns_topic.redshift_events[0].arn

  source_type = "cluster"
  source_ids = [
    aws_redshift_cluster.analytics[0].id
  ]

  severity = "INFO"

  # Selected from "aws redshift describe-event-categories" command output
  # Used events are:
  # - EventId: "REDSHIFT-EVENT-3618"
  #   Description = "The cluster <cluster name> pause operation started at <UTC time>."
  #   Category: "management"
  #   Severity: "INFO"
  # - EventId: "REDSHIFT-EVENT-3622"
  #   Description = "The cluster <cluster name> was resumed at <UTC time>."
  #   Category: "monitoring"
  #   Severity: "INFO"
  event_categories = [
    "monitoring",
    "management"
  ]
}
