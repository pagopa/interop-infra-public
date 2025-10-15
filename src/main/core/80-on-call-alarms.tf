moved {
  from = aws_cloudwatch_metric_alarm.on_call_token_5xx
  to   = aws_cloudwatch_metric_alarm.on_call_token_5xx[0]
}

resource "aws_cloudwatch_metric_alarm" "on_call_token_5xx" {
  count = local.on_call_env ? 1 : 0

  alarm_name = format("on-call-apigw-token-5xx-%s", var.env)

  alarm_actions = [aws_sns_topic.on_call_opsgenie[0].arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 60 # 60%
  evaluation_periods  = 15 # 60 periods, 1 minute each
  datapoints_to_alarm = 3  # 3 periods breaching the threshold in the last N evaluation_periods
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    label       = "5xxPercentage"
    expression  = "(m1/m2)*100"
    return_data = true
  }

  metric_query {
    id          = "m1"
    label       = "PostToken5xx"
    return_data = false

    metric {
      stat        = "Sum"
      period      = 60 # 1 minute
      metric_name = "5XXError"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiName  = module.interop_auth_apigw.apigw_name
        Stage    = var.env
        Method   = "POST"
        Resource = "/token.oauth2"
      }
    }
  }

  metric_query {
    id          = "m2"
    label       = "PostTokenCount"
    return_data = false

    metric {
      stat        = "Sum"
      period      = 60 # 1 minute
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiName  = module.interop_auth_apigw.apigw_name
        Stage    = var.env
        Method   = "POST"
        Resource = "/token.oauth2"
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "on_call_token_4xx" {
  count = local.on_call_env ? 1 : 0

  alarm_name = format("on-call-apigw-token-4xx-%s", var.env)

  alarm_actions = [aws_sns_topic.on_call_opsgenie[0].arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 60 # 60%
  evaluation_periods  = 15 # 60 periods, 1 minute each
  datapoints_to_alarm = 7  # 7 periods breaching the threshold in the last N evaluation_periods
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    label       = "4xxPercentage"
    expression  = "(m1/m2)*100"
    return_data = true
  }

  metric_query {
    id          = "m1"
    label       = "PostToken4xx"
    return_data = false

    metric {
      stat        = "Sum"
      period      = 60 # 1 minute
      metric_name = "4XXError"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiName  = module.interop_auth_apigw.apigw_name
        Stage    = var.env
        Method   = "POST"
        Resource = "/token.oauth2"
      }
    }
  }

  metric_query {
    id          = "m2"
    label       = "PostTokenCount"
    return_data = false

    metric {
      stat        = "Sum"
      period      = 60 # 1 minute
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiName  = module.interop_auth_apigw.apigw_name
        Stage    = var.env
        Method   = "POST"
        Resource = "/token.oauth2"
      }
    }
  }
}

locals {
  on_call_deployments = local.on_call_env ? {
    auth_server = "interop-be-authorization-server-node"
  } : {}
}

resource "aws_cloudwatch_metric_alarm" "on_call_readiness_pods" {
  for_each = local.on_call_deployments

  alarm_name        = format("on-call-k8s-%s-readiness-pods-%s", replace(each.key, "_", "-"), var.env)
  alarm_description = format("No ready pods for %s K8s deployment", each.value)

  alarm_actions = [aws_sns_topic.on_call_opsgenie[0].arn]

  comparison_operator = "LessThanThreshold"
  statistic           = "Minimum"
  threshold           = 1
  period              = 60 # 1 minute
  evaluation_periods  = 10 # 10 periods, 1 minute each
  datapoints_to_alarm = 5  # 5 periods breaching the threshold in the last N evaluation_periods
  treat_missing_data  = "missing"

  metric_name = "kube_deployment_status_replicas_ready"
  namespace   = "ContainerInsights"

  dimensions = {
    ClusterName = module.eks.cluster_name
    Service     = each.value
    Namespace   = var.env
  }
}
