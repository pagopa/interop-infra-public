locals {
  is_sns_topic_present = var.alarm_sns_topic_arn == "" ? false : true
}

data "aws_sqs_queue" "queue" {
  name = var.queue_name
}

resource "aws_cloudwatch_metric_alarm" "sqs_alarm" {
  alarm_name          = "${var.queue_name}-message-age-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = var.alarm_metric_name
  namespace           = "AWS/SQS"
  period              = var.alarm_period
  statistic           = var.alarm_statistic
  threshold           = var.alarm_threshold_seconds
  alarm_description   = "Age of oldest message in the queue"
  alarm_actions       = local.is_sns_topic_present ? [var.alarm_sns_topic_arn] : null
  treat_missing_data  = var.alarm_treat_missing_data
  dimensions = {
    QueueName = var.queue_name
  }
  datapoints_to_alarm = var.datapoints_to_alarm
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "sqs-${replace(var.queue_name, ".", "-")}"
  dashboard_body = templatefile("${path.module}/queue_monitoring_dahsboard.json",
    {
      QueueName = var.queue_name,
      Region    = var.region
    }
  )
}
