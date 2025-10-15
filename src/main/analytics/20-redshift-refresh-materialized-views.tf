# In the resource names "mv" stand for Materialized Views; they are defined on RedShift

locals {

  # Used Database User
  mv_refresher_redshift_db_user = format("%s_mv_refresher_user", var.env)
}

resource "aws_cloudwatch_event_rule" "call_mv_refresh_lambda" {
  count = local.deploy_mv_refresh_lambda ? 1 : 0

  name        = format("%s-analytics-refresh-redshift-mv-schedule-%s", local.project, var.env)
  description = "Call a materialized views refresh lambda every 3 minutes"

  schedule_expression = "rate(3 minutes)"
}

resource "aws_cloudwatch_event_target" "call_mv_refresh_lambda_target" {
  count = local.deploy_mv_refresh_lambda ? 1 : 0

  rule      = aws_cloudwatch_event_rule.call_mv_refresh_lambda[0].name
  target_id = format("%s-WakeMvRefreshLambda-%s", local.project, var.env)
  arn       = aws_lambda_function.mv_refresh_lambda[0].arn
}

resource "aws_lambda_permission" "mv_refresh_lambda_allow_event_bridge" {
  count = local.deploy_mv_refresh_lambda ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mv_refresh_lambda[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.call_mv_refresh_lambda[0].arn
}

module "mv_refresh_lambda_code_archive" {
  count  = local.deploy_mv_refresh_lambda ? 1 : 0
  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/download-and-pin-file?ref=v1.28.0"

  file_url        = var.redshift_materialized_views_refresher_lambda.zip_url
  file_sha256_hex = var.redshift_materialized_views_refresher_lambda.zip_sha256_hex
  file_cache_key  = "analytics-refresh-mv.zip"
}

resource "aws_lambda_function" "mv_refresh_lambda" {
  count = local.deploy_mv_refresh_lambda ? 1 : 0

  filename         = module.mv_refresh_lambda_code_archive[0].downloaded_file_location
  source_code_hash = module.mv_refresh_lambda_code_archive[0].file_sha256_base64

  function_name = format("%s-analytics-refresh-redshift-mv-%s", local.project, var.env)
  role          = aws_iam_role.mv_refresh_lambda_role[0].arn
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  timeout       = 600 # 10 minutes
  memory_size   = 150 # MB

  environment {
    variables = {
      REDSHIFT_CLUSTER_IDENTIFIER = aws_redshift_cluster.analytics[0].cluster_identifier

      REDSHIFT_DATABASE_NAME = aws_redshift_cluster.analytics[0].database_name

      REDSHIFT_DB_USER = local.mv_refresher_redshift_db_user

      VIEWS_SCHEMAS_NAMES = jsonencode(["views", "sub_views"])
      PROCEDURES_SCHEMA   = "sub_views"

      # Minimum number of seconds between two refresh of the same materialized views
      # - No minimum interval for incremental mv (the effective refresh interval will be the lambda
      #   scheduling rate).
      # INCREMENTAL_MV_MIN_INTERVAL_SECONDS = "0"
      # - Set minimum interval for not incremental refresh mv. The real refresh interval is
      #   influenced by the lambda scheduling rate.
      NOT_INCREMENTAL_MV_MIN_INTERVAL_SECONDS = "${10 * 60}" # 10 minutes
    }
  }

  depends_on = [
    aws_iam_role.mv_refresh_lambda_role
  ]
}

resource "aws_cloudwatch_log_group" "mv_refresh_lambda_logs" {
  count = local.deploy_mv_refresh_lambda ? 1 : 0

  name = "/aws/lambda/${aws_lambda_function.mv_refresh_lambda[0].function_name}"

  retention_in_days = var.env == "prod" ? 30 : 7
}


resource "aws_iam_role" "mv_refresh_lambda_role" {
  count = local.deploy_mv_refresh_lambda ? 1 : 0

  name = format("%s-analytics-refresh-redshift-mv-role-%s", local.project, var.env)

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

resource "aws_iam_policy" "mv_refresh_lambda_policy" {
  count = local.deploy_mv_refresh_lambda ? 1 : 0

  name        = format("%s-analytics-refresh-redshift-mv-policy-%s", local.project, var.env)
  description = "IAM policy for Lambda to interact with Redshift Data API and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "redshift:DescribeClusters"
        ],
        Resource = [
          format(
            "arn:aws:redshift:%s:%s:cluster:%s",
            var.aws_region,
            data.aws_caller_identity.current.account_id,
            aws_redshift_cluster.analytics[0].cluster_identifier
          )
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:BatchExecuteStatement"
        ],
        Resource = [
          format(
            "arn:aws:redshift:%s:%s:cluster:%s",
            var.aws_region,
            data.aws_caller_identity.current.account_id,
            aws_redshift_cluster.analytics[0].cluster_identifier
          )
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult"
        ],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = [
          "redshift:GetClusterCredentials"
        ],
        Resource = [
          format(
            "arn:aws:redshift:%s:%s:dbname:%s/%s",
            var.aws_region,
            data.aws_caller_identity.current.account_id,
            aws_redshift_cluster.analytics[0].cluster_identifier,
            aws_redshift_cluster.analytics[0].database_name
          ),
          format(
            "arn:aws:redshift:%s:%s:dbuser:%s/%s",
            var.aws_region,
            data.aws_caller_identity.current.account_id,
            aws_redshift_cluster.analytics[0].cluster_identifier,
            local.mv_refresher_redshift_db_user
          )
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${aws_lambda_function.mv_refresh_lambda[0].function_name}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mv_refresh_lambda_role_attach_policy" {
  count = local.deploy_mv_refresh_lambda ? 1 : 0

  role       = aws_iam_role.mv_refresh_lambda_role[0].name
  policy_arn = aws_iam_policy.mv_refresh_lambda_policy[0].arn
}

resource "aws_cloudwatch_metric_alarm" "mv_refresh_lambda_errors" {
  count = local.deploy_mv_refresh_lambda ? 1 : 0

  alarm_name        = format("%s-analytics-refresh-redshift-mv-errors-%s", local.project, var.env)
  alarm_description = "Lambda analytics-refresh-redshift-mv Hash Errors"

  alarm_actions = [aws_sns_topic.analytics_alarms.arn]

  namespace   = "AWS/Lambda"
  metric_name = "Errors"
  dimensions = {
    FunctionName = aws_lambda_function.mv_refresh_lambda[0].function_name
  }
  statistic = "Sum"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  period              = 600 # 10 minutes
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1
}
