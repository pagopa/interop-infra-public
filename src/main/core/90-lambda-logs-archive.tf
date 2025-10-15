# TODO: handle if it's missing
data "aws_cloudwatch_log_group" "app_logs" {
  name = var.eks_application_log_group_name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

// TODO split roles, rename
resource "aws_iam_role" "lambda_role" {
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  name                = "interop-logs-lambda-${var.env}-es1"

  inline_policy {
    name = "InteropLogsLambdaExportPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "logs:CreateExportTask"
          Effect   = "Allow"
          Resource = "${data.aws_cloudwatch_log_group.app_logs.arn}:*"
        },
        {
          Action   = "logs:DescribeExportTasks"
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = "logs:DescribeLogGroups"
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}


data "archive_file" "logs_dates_lambda_code" {
  type        = "zip"
  source_file = "${path.module}/lambda/log_dates/main.py"
  output_path = "${path.module}/lambda/log_dates/logs_dates_lambda_code.zip"
}

data "archive_file" "logs_export_lambda_code" {
  type        = "zip"
  source_file = "${path.module}/lambda/log_export/main.py"
  output_path = "${path.module}/lambda/log_export/logs_export_lambda_code.zip"
}

resource "aws_lambda_function" "logs_dates_lambda" {
  filename         = data.archive_file.logs_dates_lambda_code.output_path
  function_name    = "interop-logs-dates-${var.env}"
  handler          = "main.handler"
  memory_size      = 128
  package_type     = "Zip"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.9"
  source_code_hash = data.archive_file.logs_dates_lambda_code.output_base64sha256
  ephemeral_storage {
    size = 512
  }
  tracing_config {
    mode = "PassThrough"
  }
  architectures = [
    "x86_64"
  ]
}

resource "aws_lambda_function" "logs_export_lambda" {
  filename         = data.archive_file.logs_export_lambda_code.output_path
  function_name    = "interop-logs-export-${var.env}"
  handler          = "main.handler"
  memory_size      = 128
  package_type     = "Zip"
  role             = aws_iam_role.lambda_role.arn
  runtime          = "python3.9"
  source_code_hash = data.archive_file.logs_export_lambda_code.output_base64sha256
  ephemeral_storage {
    size = 512
  }
  tracing_config {
    mode = "PassThrough"
  }
  architectures = [
    "x86_64"
  ]
}
