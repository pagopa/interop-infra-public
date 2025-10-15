resource "aws_iam_role" "logs_automation" {
  name = format("%s-logs-automation-%s-es1", local.project, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "LogsAutomationPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "logs:DescribeExportTasks"
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = "lambda:InvokeFunction"
          Resource = [
            "${aws_lambda_function.logs_dates_lambda.arn}:*",
            "${aws_lambda_function.logs_export_lambda.arn}:*"
          ]
        },
        {
          Effect   = "Allow"
          Action   = "glue:StartCrawler"
          Resource = aws_glue_crawler.app_logs.arn
        }
      ]
    })
  }
}

resource "aws_sfn_state_machine" "logs_automation" {
  name     = format("%s-logs-automation-%s", local.project, var.env)
  role_arn = aws_iam_role.logs_automation.arn

  definition = templatefile("${path.module}/assets/state-machines/logs-automation.tpl.json", {
    LogsDatesLambdaArn  = aws_lambda_function.logs_dates_lambda.qualified_arn
    LogsExportLambdaArn = aws_lambda_function.logs_export_lambda.qualified_arn
  })
}
