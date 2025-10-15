resource "aws_iam_role" "quicksight_redshift_access" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name        = format("%s-analytics-quicksight-redshift-access-%s", local.project, var.env)
  description = "IAM role used by QuickSight to create VPC connection and Discover RedShift DB"

  assume_role_policy = data.aws_iam_policy_document.quicksight_can_assume.json
}

resource "aws_iam_role_policy" "quicksight_redshift_access_policy" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name = "QuickSightVpcPolicy"
  role = aws_iam_role.quicksight_redshift_access[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateVpcConnection"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = [
          "*"
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "quicksight_can_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["quicksight.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:quicksight:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

# This resource must be in the "Identity Center" region
resource "aws_quicksight_account_subscription" "quicksight_subscription" {
  count = local.deploy_redshift_cluster ? 1 : 0

  provider = aws.identity_center_region

  account_name          = title(format("%s-Analytics-%s", local.project, var.env))
  authentication_method = "IAM_IDENTITY_CENTER"
  edition               = "ENTERPRISE"
  notification_email    = var.quicksight_notification_email

  iam_identity_center_instance_arn = var.quicksight_identity_center_arn

  admin_group  = [format("%s-%s-quicksight-admins", local.project, var.env)]
  author_group = [format("%s-%s-quicksight-authors", local.project, var.env)]
  reader_group = [format("%s-%s-quicksight-readers", local.project, var.env)]
}

# This resource must be in the "Identity Center" region
resource "aws_quicksight_account_settings" "quicksight_account_settings" {
  count = local.deploy_redshift_cluster ? 1 : 0

  provider = aws.identity_center_region

  # Change before destroy
  termination_protection_enabled = true

  depends_on = [aws_quicksight_account_subscription.quicksight_subscription]
}

resource "aws_quicksight_vpc_connection" "quicksight_to_redshift_connection" {
  count = local.deploy_redshift_cluster ? 1 : 0

  vpc_connection_id = format("%s_quicksight_to_redshift_%s", local.project, var.env)
  name              = "QuickSight to RedShift VPC connection"

  role_arn           = aws_iam_role.quicksight_redshift_access[0].arn
  security_group_ids = [data.aws_security_group.quicksight_analytic[0].id]
  subnet_ids         = data.aws_subnets.analytics[0].ids

  depends_on = [
    aws_quicksight_account_subscription.quicksight_subscription,
    aws_iam_role_policy.quicksight_redshift_access_policy
  ]
}

# - Database connection that wrap Redshift default database connection parameters and credentials
#   This datasource is shared to all ${var.env} authors and admins.
resource "aws_quicksight_data_source" "analytics_views" {
  count = local.deploy_redshift_cluster ? 1 : 0

  data_source_id = format("%s_analytics_views_%s", local.project, var.env)
  name           = format("Views inside %s analytics database (%s env)", local.project, var.env)

  type = "REDSHIFT"

  vpc_connection_properties {
    vpc_connection_arn = aws_quicksight_vpc_connection.quicksight_to_redshift_connection[0].arn
  }
  parameters {
    redshift {
      host     = data.aws_redshift_cluster.analytics[0].endpoint
      port     = data.aws_redshift_cluster.analytics[0].port
      database = data.aws_redshift_cluster.analytics[0].database_name
    }
  }
  credentials {
    secret_arn = data.aws_secretsmanager_secret_version.quicksight_user_secret_version[0].arn
  }
  ssl_properties {
    disable_ssl = false
  }

  permission {
    principal = "${local.quicksight_groups_arn_prefix}-quicksight-admins"
    actions   = local.quicksight_datasource_read_write_actions
  }

  permission {
    principal = "${local.quicksight_groups_arn_prefix}-quicksight-authors"
    actions   = local.quicksight_datasource_read_only_actions
  }

  tags = {
    DatabaseName = data.aws_redshift_cluster.analytics[0].database_name
  }
}
