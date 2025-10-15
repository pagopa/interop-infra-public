resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  count = var.create_cloudwatch_alarm ? 1 : 0

  alarm_name        = format("%s-apigw-5xx", var.api_name)
  alarm_description = format("%s 5xx errors", var.api_name)

  alarm_actions = var.maintenance_mode ? [] : [var.sns_topic_arn]

  metric_name = "5XXError"
  namespace   = "AWS/ApiGateway"
  dimensions = {
    ApiName = var.api_name
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  threshold           = var.alarm_5xx_threshold
  period              = var.alarm_5xx_period
  evaluation_periods  = var.alarm_5xx_eval_periods
  datapoints_to_alarm = var.alarm_5xx_datapoints
}

resource "aws_cloudwatch_dashboard" "this" {
  count = var.create_cloudwatch_dashboard ? 1 : 0

  dashboard_name = replace(format("apigw-%s", var.api_name), ".", "-")
  dashboard_body = templatefile("${path.module}/apigw-dashboard.tpl.json", {
    Region    = data.aws_region.current.name
    ApiGwName = var.api_name
  })
}
