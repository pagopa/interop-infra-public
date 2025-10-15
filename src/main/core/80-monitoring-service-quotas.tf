resource "aws_cloudwatch_metric_alarm" "kms_rsa_quota" {
  alarm_name        = format("kms-rsa-quota-%s", var.env)
  alarm_description = "KMS request quota for RSA operations"

  alarm_actions = [aws_sns_topic.platform_alarms.arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 60
  datapoints_to_alarm = 1
  evaluation_periods  = 5
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "pct_utilization"
    label       = "% Utilization"
    expression  = "(usage_data/(SERVICE_QUOTA(usage_data)))*100"
    return_data = true
  }

  metric_query {
    id          = "usage_data"
    label       = "CallCount"
    return_data = false

    metric {
      metric_name = "CallCount"
      namespace   = "AWS/Usage"
      stat        = "Sum"
      period      = 60 # 1 minute

      dimensions = {
        Service  = "KMS"
        Type     = "API"
        Resource = "CryptographicOperationsRsa"
        Class    = "None"
      }
    }
  }
}

resource "aws_cloudwatch_dashboard" "kms_rsa_quota" {
  dashboard_name = format("kms-%s", var.env)
  dashboard_body = <<-EOT
    {
      "widgets":[
        {
          "type":"alarm",
          "x":0,
          "y":0,
          "width":24,
          "height":2,
          "properties":{
            "title":"Alarms status",
            "alarms":[
              "${aws_cloudwatch_metric_alarm.kms_rsa_quota.arn}"
            ]
          }
        },
        {
          "type":"metric",
          "x":0,
          "y":0,
          "width":24,
          "height":6,
          "properties":{
            "title":"${aws_cloudwatch_metric_alarm.kms_rsa_quota.alarm_name}",
            "annotations":{
              "alarms":[
                "${aws_cloudwatch_metric_alarm.kms_rsa_quota.arn}"
              ]
            },
            "view":"timeSeries",
            "stacked":false
          }
        }
      ]
    }
  EOT
}
