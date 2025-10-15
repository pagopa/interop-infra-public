resource "aws_iam_role" "redshift_describe_clusters" {
  count = local.deploy_redshift_cluster && var.redshift_enable_cross_account_access_account_id != null ? 1 : 0

  name = format("%s-redshift-describe-clusters-cross-account-access-%s-es1", local.project, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole"
      Principal = {
        AWS = "arn:aws:iam::${var.redshift_enable_cross_account_access_account_id}:root"
      },
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::${var.redshift_enable_cross_account_access_account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_*"
        }
      }
    }]
  })

  inline_policy {
    name = "RedshiftDescribeClustersCrossAccountPolicy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Action = [
          "redshift:DescribeClusters",
          "redshift:DescribeLoggingStatus"
        ]
        Resource = "*"
      }]
    })
  }
}

resource "aws_iam_role" "redshift_get_master_secret" {
  count = local.deploy_redshift_cluster && var.redshift_enable_cross_account_access_account_id != null ? 1 : 0

  name = format("%s-redshift-get-master-secret-cross-account-access-%s-es1", local.project, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole"
      Principal = {
        AWS = "arn:aws:iam::${var.redshift_enable_cross_account_access_account_id}:root"
      },
      Condition = {
        ArnLike = {
          "aws:PrincipalArn" = "arn:aws:iam::${var.redshift_enable_cross_account_access_account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_FullAdmin*"
        }
      }
    }]
  })

  inline_policy {
    name = "RedshiftGetMasterSecretCrossAccountPolicy"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.redshift_master[0].arn,
          aws_secretsmanager_secret_version.redshift_master[0].arn
        ]
      }]
    })
  }
}

resource "aws_iam_role" "redshift_s3_copy" {
  name = format("%s-analytics-redshift-s3-copy-%s", local.project, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "redshift_s3_copy" {
  name = "InteropAnalyticsRedshiftS3Copy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GlueBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:HeadObject"
        ]
        Resource = [
          module.glue_spark_outputs_bucket[0].s3_bucket_arn,
          "${module.glue_spark_outputs_bucket[0].s3_bucket_arn}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "redshift_s3_copy" {
  role       = aws_iam_role.redshift_s3_copy.name
  policy_arn = aws_iam_policy.redshift_s3_copy.arn
}

resource "aws_iam_role" "jwt_audit_etl" {
  count = local.deploy_spark_etl_jobs ? 1 : 0

  name = format("%s-analytics-glue-jwt-audit-etl-%s", local.project, var.env)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "jwt_audit_etl" {
  count = local.deploy_spark_etl_jobs ? 1 : 0

  name = "InteropAnalyticsGlueSparkJwtAuditEtl"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GlueBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          module.glue_spark_assets_bucket[0].s3_bucket_arn,
          "${module.glue_spark_assets_bucket[0].s3_bucket_arn}/*",
          module.glue_spark_outputs_bucket[0].s3_bucket_arn,
          "${module.glue_spark_outputs_bucket[0].s3_bucket_arn}/*",
        ]
      },
      {
        Sid    = "GeneratedJwtBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          data.aws_s3_bucket.jwt_audit_source.arn,
          "${data.aws_s3_bucket.jwt_audit_source.arn}/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jwt_audit_etl" {
  count = local.deploy_spark_etl_jobs ? 1 : 0

  role       = aws_iam_role.jwt_audit_etl[0].name
  policy_arn = aws_iam_policy.jwt_audit_etl[0].arn
}

resource "aws_iam_role_policy_attachment" "glue_service_role" {
  count = local.deploy_spark_etl_jobs ? 1 : 0

  role       = aws_iam_role.jwt_audit_etl[0].name
  policy_arn = data.aws_iam_policy.glue_service_role[0].arn
}
