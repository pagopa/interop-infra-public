resource "aws_sqs_queue" "uptime_cost_optimization_dlq" {
  count = local.deploy_uptime_cost_optimization ? 1 : 0

  name = format("%s-eventbridge-uptime-cost-optimization-dlq-%s", local.project, var.env)

  message_retention_seconds = 1209600 # 14 days
  max_message_size          = 262144  # 256 KB
}

resource "aws_iam_policy" "aurora_uptime_cost_optimization" {
  count = local.deploy_uptime_cost_optimization ? 1 : 0

  name = "InteropAuroraUptimeCostOptimization"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:StartDBCluster",
          "rds:StopDBCluster"
        ]
        Resource = module.platform_data.cluster_arn
      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.uptime_cost_optimization_dlq[0].arn
      }
    ]
  })
}

resource "aws_iam_role" "uptime_cost_optimization" {
  count = local.deploy_uptime_cost_optimization ? 1 : 0

  name = format("%s-eventbridge-uptime-cost-optimization-%s", local.project, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [aws_iam_policy.aurora_uptime_cost_optimization[0].arn]
}

resource "aws_scheduler_schedule_group" "uptime_cost_optimization" {
  count = local.deploy_uptime_cost_optimization ? 1 : 0

  name = format("%s-uptime-cost-optimization-%s", local.project, var.env)
}

resource "aws_scheduler_schedule" "start_aurora_working_hours" {
  count = local.deploy_uptime_cost_optimization ? 1 : 0

  name       = format("%s-start-aurora-working-hours-%s", local.project, var.env)
  group_name = aws_scheduler_schedule_group.uptime_cost_optimization[0].name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(40 7 ? * MON-FRI *)"
  schedule_expression_timezone = "Europe/Rome"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBCluster"
    role_arn = aws_iam_role.uptime_cost_optimization[0].arn

    input = jsonencode({
      DbClusterIdentifier = module.platform_data.cluster_id
    })

    retry_policy {
      maximum_event_age_in_seconds = 3600
    }

    dead_letter_config {
      arn = aws_sqs_queue.uptime_cost_optimization_dlq[0].arn
    }
  }
}

resource "aws_scheduler_schedule" "stop_aurora_after_working_hours" {
  count = local.deploy_uptime_cost_optimization ? 1 : 0

  name       = format("%s-stop-aurora-after-working-hours-%s", local.project, var.env)
  group_name = aws_scheduler_schedule_group.uptime_cost_optimization[0].name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(5 20 ? * MON-FRI *)"
  schedule_expression_timezone = "Europe/Rome"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBCluster"
    role_arn = aws_iam_role.uptime_cost_optimization[0].arn

    input = jsonencode({
      DbClusterIdentifier = module.platform_data.cluster_id
    })

    retry_policy {
      maximum_event_age_in_seconds = 3600
    }

    dead_letter_config {
      arn = aws_sqs_queue.uptime_cost_optimization_dlq[0].arn
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "sqs_uptime_cost_optimization_dlq" {
  count = local.deploy_uptime_cost_optimization ? 1 : 0

  alarm_name          = format("sqs-uptime-cost-optimization-dlq-has-messages-%s", var.env)
  alarm_description   = "DLQ for Uptime Cost Optimization has messages, it means there are failed schedules"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  alarm_actions       = [aws_sns_topic.platform_alarms.arn]
  treat_missing_data  = "notBreaching"
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
        QueueName = aws_sqs_queue.uptime_cost_optimization_dlq[0].name
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
        QueueName = aws_sqs_queue.uptime_cost_optimization_dlq[0].name
      }
    }
  }
}
