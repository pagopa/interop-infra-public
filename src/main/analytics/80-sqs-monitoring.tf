resource "aws_cloudwatch_metric_alarm" "sqs_jwt_audit" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  depends_on = [aws_sqs_queue.jwt_audit[0]]

  alarm_name          = "sqs-${aws_sqs_queue.jwt_audit[0].name}-message-age-${var.env}"
  alarm_description   = "Age of oldest message in the queue"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "120" # 2 minutes
  alarm_actions       = [aws_sns_topic.analytics_alarms.arn]
  treat_missing_data  = "notBreaching"
  dimensions = {
    QueueName = aws_sqs_queue.jwt_audit[0].name
  }
  datapoints_to_alarm = "1"
}

resource "aws_cloudwatch_metric_alarm" "sqs_alb_logs" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  depends_on = [aws_sqs_queue.alb_logs[0]]

  alarm_name          = "sqs-${aws_sqs_queue.alb_logs[0].name}-message-age-${var.env}"
  alarm_description   = "Age of oldest message in the queue"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "120" # 2 minutes
  alarm_actions       = [aws_sns_topic.analytics_alarms.arn]
  treat_missing_data  = "notBreaching"
  dimensions = {
    QueueName = aws_sqs_queue.alb_logs[0].name
  }
  datapoints_to_alarm = "1"
}

resource "aws_cloudwatch_metric_alarm" "sqs_application_audit_fallback" {
  count = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? 1 : 0

  depends_on = [aws_sqs_queue.application_audit_fallback[0]]

  alarm_name          = "sqs-${aws_sqs_queue.application_audit_fallback[0].name}-approximate-number-messages"
  alarm_description   = "Approximate number of messages on ${aws_sqs_queue.application_audit_fallback[0].name} queue"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  alarm_actions       = [aws_sns_topic.analytics_alarms.arn]
  treat_missing_data  = "missing"
  datapoints_to_alarm = "1"

  metric_query {
    id          = "e1"
    label       = "Approximate number of messages"
    expression  = "m1+m2"
    return_data = true
  }

  metric_query {
    id          = "m1"
    label       = "Approximate number of messages visible"
    return_data = false

    metric {
      stat   = "Maximum"
      period = 60 # 1 minute

      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"

      dimensions = {
        QueueName = aws_sqs_queue.application_audit_fallback[0].name
      }
    }
  }

  metric_query {
    id          = "m2"
    label       = "Approximate number of messages not visible"
    return_data = false

    metric {
      stat   = "Maximum"
      period = 60 # 1 minute

      metric_name = "ApproximateNumberOfMessagesNotVisible"
      namespace   = "AWS/SQS"

      dimensions = {
        QueueName = aws_sqs_queue.application_audit_fallback[0].name
      }
    }
  }
}