resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  alarm_name        = format("%s-apigw-5xx", var.apigw_name)
  alarm_description = format("%s 5xx errors", var.apigw_name)

  alarm_actions = [var.sns_topic_arn]

  metric_name = "5XXError"
  namespace   = "AWS/ApiGateway"
  dimensions = {
    ApiName = var.apigw_name
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  threshold           = var.alarm_5xx_threshold
  period              = var.alarm_5xx_period
  evaluation_periods  = var.alarm_5xx_eval_periods
  datapoints_to_alarm = var.alarm_5xx_datapoints
}
