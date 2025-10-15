resource "aws_iam_role" "events_logs_automation" {
  name = format("interop-events-logs-automation-%s-es1", var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "StartLogsAutomation"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "states:StartExecution"
          Resource = aws_sfn_state_machine.logs_automation.arn
        }
      ]
    })
  }
}

resource "aws_cloudwatch_event_rule" "logs_automation_schedule" {
  name = format("interop-applications-logs-schedule-%s", var.env)

  schedule_expression = "cron(0 1 * * ? *)"
}

resource "aws_cloudwatch_event_target" "logs_automation" {
  count = var.eks_application_log_group_name != null ? 1 : 0

  target_id = "StartLogsAutomationExecution"

  rule     = aws_cloudwatch_event_rule.logs_automation_schedule.name
  arn      = aws_sfn_state_machine.logs_automation.arn
  role_arn = aws_iam_role.events_logs_automation.arn

  input = jsonencode({
    log_group = var.eks_application_log_group_name
    bucket    = module.application_logs_bucket.s3_bucket_id
    crawler   = aws_glue_crawler.app_logs.id
  })
}

resource "aws_cloudwatch_event_rule" "logs_automation_failure" {
  name = format("interop-logs-automation-errors-%s", var.env)

  event_bus_name = "default"
  event_pattern = jsonencode({
    source      = ["aws.states"]
    detail-type = ["Step Functions Execution Status Change"]
    detail = {
      status          = ["FAILED", "TIMED_OUT"]
      stateMachineArn = [aws_sfn_state_machine.logs_automation.arn]
    }
  })
}

resource "aws_cloudwatch_event_target" "logs_automation_failure" {
  target_id = "SendNotification"

  rule = aws_cloudwatch_event_rule.logs_automation_failure.name
  arn  = aws_sns_topic.logs_automation_errors.arn
}

resource "aws_cloudwatch_event_rule" "aws_health" {
  count = var.env == "prod" ? 1 : 0

  name = format("interop-aws-health-%s", var.env)

  event_bus_name = "default"
  event_pattern = jsonencode({
    source      = ["aws.health"],
    detail-type = ["AWS Health Event"],
    detail = {
      eventRegion = [var.aws_region]
    }
  })
}

resource "aws_cloudwatch_event_target" "aws_health_notification" {
  count = var.env == "prod" ? 1 : 0

  target_id = "SendNotification"

  rule = aws_cloudwatch_event_rule.aws_health[0].name
  arn  = aws_sns_topic.platform_alarms.arn
}
