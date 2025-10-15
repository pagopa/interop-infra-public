data "aws_iam_policy" "transfer_logging" {
  count = local.deploy_anac_sftp ? 1 : 0

  name = "AWSTransferLoggingAccess"
}

data "archive_file" "sftp_anac_authorizer" {
  count = local.deploy_anac_sftp ? 1 : 0

  type       = "zip"
  source_dir = "${path.module}/lambda/sftp_anac_authorizer/"
  excludes   = ["node_modules", "dist.zip"]

  output_path = "${path.module}/lambda/sftp_anac_authorizer/dist.zip"
}

resource "aws_iam_role" "sftp_anac_authorizer" {
  count = local.deploy_anac_sftp ? 1 : 0

  name = "interop-sftp-anac-authorizer-${var.env}-es1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  inline_policy {
    name = "SftpAnacSecrets"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "secretsmanager:GetSecretValue"
          Effect = "Allow"
          Resource = [
            aws_secretsmanager_secret.anac_sftp_username.arn,
            aws_secretsmanager_secret.anac_sftp_password.arn,
          ]
        },
      ]
    })
  }
}

resource "aws_lambda_function" "sftp_anac_authorizer" {
  count = local.deploy_anac_sftp ? 1 : 0

  filename         = data.archive_file.sftp_anac_authorizer[0].output_path
  function_name    = "interop-sftp-anac-authorizer-${var.env}"
  handler          = "index.handler"
  memory_size      = 128
  package_type     = "Zip"
  role             = aws_iam_role.sftp_anac_authorizer[0].arn
  runtime          = "nodejs18.x"
  source_code_hash = data.archive_file.sftp_anac_authorizer[0].output_base64sha256
  architectures    = ["x86_64"]

  environment {
    variables = {
      SFTP_ANAC_USERNAME_SECRET_NAME      = aws_secretsmanager_secret.anac_sftp_username.name
      SFTP_ANAC_USER_PASSWORD_SECRET_NAME = aws_secretsmanager_secret.anac_sftp_password.name
      SFTP_ANAC_BUCKET_NAME               = module.anac_sftp_bucket[0].s3_bucket_id
      SFTP_ANAC_BUCKET_ACCESS_ROLE_ARN    = aws_iam_role.sftp_anac_readonly[0].arn
    }
  }
}

resource "aws_lambda_permission" "allow_sftp_anac" {
  count = local.deploy_anac_sftp ? 1 : 0

  statement_id  = "AllowInvokeFromSftpAnac"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sftp_anac_authorizer[0].function_name
  principal     = "transfer.amazonaws.com"
  source_arn    = aws_transfer_server.sftp_anac[0].arn
}

resource "aws_iam_role" "sftp_anac_logging" {
  count = local.deploy_anac_sftp ? 1 : 0

  name = format("InteropSftpAnacLogging%sEs1", title(var.env))

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "transfer.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [data.aws_iam_policy.transfer_logging[0].arn]
}

resource "aws_security_group" "sftp_anac" {
  count = local.deploy_anac_sftp ? 1 : 0

  description = "SFTP ANAC"
  name        = "interop-sftp-anac-${var.env}"

  vpc_id = module.vpc.vpc_id

  ingress {
    description = "From pods"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [
      module.eks.cluster_primary_security_group_id,
    ]
  }

  ingress {
    description = "From VPN clients"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [
      aws_security_group.vpn_clients.id
    ]
  }
}

resource "aws_transfer_server" "sftp_anac" {
  count = local.deploy_anac_sftp ? 1 : 0

  protocols              = ["SFTP"]
  identity_provider_type = "AWS_LAMBDA"
  function               = aws_lambda_function.sftp_anac_authorizer[0].arn
  domain                 = "S3"
  logging_role           = aws_iam_role.sftp_anac_logging[0].arn

  endpoint_type = "VPC"

  endpoint_details {
    vpc_id             = module.vpc.vpc_id
    security_group_ids = [aws_security_group.sftp_anac[0].id]
    subnet_ids         = [data.aws_subnets.int_lbs.ids[0]]
  }
}

resource "aws_iam_role" "sftp_anac_readonly" {
  count = local.deploy_anac_sftp ? 1 : 0

  name = format("InteropSftpAnacS3%sEs1", title(var.env))

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "transfer.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  inline_policy {
    name = "S3ReadOnly"

    policy = jsonencode({
      Version : "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "s3:ListBucket"
          Resource = module.anac_sftp_bucket[0].s3_bucket_arn
        },
        {
          Effect = "Allow"
          Action = "s3:Get*"
          Resource = [
            module.anac_sftp_bucket[0].s3_bucket_arn,
            "${module.anac_sftp_bucket[0].s3_bucket_arn}/*"
          ]
      }]
    })
  }
}
