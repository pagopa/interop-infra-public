
resource "aws_sns_topic_subscription" "datasets_schedule_lambda_subscription_to_redshift_events" {
  count = local.deploy_datasets_schedule_lambda ? 1 : 0

  topic_arn = data.aws_sns_topic.redshift_events[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.datasets_schedule_lambda[0].arn
}

resource "aws_lambda_permission" "datasets_schedule_lambda_allow_sns" {
  count = local.deploy_datasets_schedule_lambda ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.datasets_schedule_lambda[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = data.aws_sns_topic.redshift_events[0].arn
}

module "datasets_schedule_lambda_code_archive" {
  count  = local.deploy_datasets_schedule_lambda ? 1 : 0
  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/download-and-pin-file?ref=v1.28.0"

  file_url        = var.quicksight_datasets_schedule_lambda.zip_url
  file_sha256_hex = var.quicksight_datasets_schedule_lambda.zip_sha256_hex
  file_cache_key  = "quicksight-alert-scheduling-on-off.zip"
}

resource "aws_lambda_function" "datasets_schedule_lambda" {
  count = local.deploy_datasets_schedule_lambda ? 1 : 0

  filename         = module.datasets_schedule_lambda_code_archive[0].downloaded_file_location
  source_code_hash = module.datasets_schedule_lambda_code_archive[0].file_sha256_base64

  function_name = format("%s-quicksight-dataset-schedule-%s", local.project, var.env)
  role          = aws_iam_role.datasets_schedule_lambda_role[0].arn
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  timeout       = 600 # 10 minutes
  memory_size   = 512 # MB

  environment {
    variables = {

    }
  }

  depends_on = [
    aws_iam_role.datasets_schedule_lambda_role
  ]
}

resource "aws_cloudwatch_log_group" "datasets_schedule_lambda_logs" {
  count = local.deploy_datasets_schedule_lambda ? 1 : 0

  name = "/aws/lambda/${aws_lambda_function.datasets_schedule_lambda[0].function_name}"

  retention_in_days = var.env == "prod" ? 30 : 7
}


resource "aws_iam_role" "datasets_schedule_lambda_role" {
  count = local.deploy_datasets_schedule_lambda ? 1 : 0

  name = format("%s-quicksight-dataset-schedule-role-%s", local.project, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "datasets_schedule_lambda_policy" {
  count = local.deploy_datasets_schedule_lambda ? 1 : 0

  name        = format("%s-quicksight-dataset-schedule-policy-%s", local.project, var.env)
  description = "IAM policy for Lambda quicksight-dataset-schedule to interact with QuickSight DataSets schedule and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowStsIdentity"
        Effect   = "Allow"
        Action   = ["sts:GetCallerIdentity"]
        Resource = "*"
      },
      {
        "Sid" : "AllowQuickSightDataSetActions",
        "Effect" : "Allow",
        "Action" : [
          "quicksight:ListDataSets",
          "quicksight:ListTagsForResource",
          "quicksight:CreateRefreshSchedule",
          "quicksight:DeleteRefreshSchedule"
        ],
        Resource = [
          format(
            "arn:aws:quicksight:%s:%s:dataset/*",
            var.aws_region,
            data.aws_caller_identity.current.account_id
          )
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${aws_lambda_function.datasets_schedule_lambda[0].function_name}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "datasets_schedule_lambda_role_attach_policy" {
  count = local.deploy_datasets_schedule_lambda ? 1 : 0

  role       = aws_iam_role.datasets_schedule_lambda_role[0].name
  policy_arn = aws_iam_policy.datasets_schedule_lambda_policy[0].arn
}

resource "aws_cloudwatch_metric_alarm" "datasets_schedule_lambda_errors" {
  count = local.deploy_datasets_schedule_lambda ? 1 : 0

  alarm_name        = format("%s-quicksight-dataset-schedule-errors-%s", local.project, var.env)
  alarm_description = "Lambda quicksight-dataset-schedule Hash Errors"

  alarm_actions = [
    data.aws_sns_topic.analytics_alarms.arn
  ]

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  dimensions = {
    FunctionName = aws_lambda_function.datasets_schedule_lambda[0].function_name
  }
  statistic = "Sum"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  period              = 300 # 5 minutes, avoid missing data is not possible, the lambda run twice a day.
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1
}
