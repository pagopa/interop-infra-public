locals {
  frontend_env_cors_domain = (var.env != "prod" ?
  format("selfcare.%s.%s", local.env_dns_name, var.dns_interop_base_domain) : format("selfcare.%s", var.dns_interop_base_domain))
}

module "jwt_well_known_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-jwt-well-known-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
        ]
        Resource = "${module.jwt_well_known_bucket.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.landing.arn
          }
        }
      }
    ]
  })
}

module "application_documents_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-application-documents-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

module "generated_jwt_details_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-generated-jwt-details-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode  = var.env == "prod" ? "COMPLIANCE" : "GOVERNANCE"
        years = 10
      }
    }
  }

  lifecycle_rule = [
    {
      id         = "GlacierRule"
      enabled    = false           # TODO: move to S3-IA instead? Need to handle existing objects in Glacier
      expiration = { days : 3650 } # delete after 10 years
      transition = {
        days : 365
        storage_class : "GLACIER"
      }
    }
  ]
}

resource "aws_s3_bucket_notification" "generated_jwt_details_put_object" {
  bucket = module.generated_jwt_details_bucket.s3_bucket_id

  topic {
    topic_arn     = aws_sns_topic.jwt_details_new_s3_object.arn
    events        = ["s3:ObjectCreated:Put"]
    filter_suffix = ".ndjson"
  }
}

module "data_lake_exports_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-data-lake-exports-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "application_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-application-logs-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service : ["logs.${var.aws_region}.amazonaws.com"]
        }
        Action   = "s3:GetBucketAcl"
        Resource = module.application_logs_bucket.s3_bucket_arn
      },
      {
        Effect = "Allow"
        Principal = {
          Service : ["logs.${var.aws_region}.amazonaws.com"]
        }
        Action   = "s3:PutObject"
        Resource = "${module.application_logs_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}

module "athena_query_results_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-athena-query-results-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id         = "Expiration"
      enabled    = true
      expiration = { days : 31 } # delete after 31 days
    }
  ]
}

module "platform_metrics_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-platform-metrics-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "allow_list_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-allow-list-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "public_dashboards_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-public-dashboards-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  cors_rule = var.env != "test" ? [] : [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["https://www.interop.pagopa.it"]
    }
  ]

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
        ]
        Resource = "${module.public_dashboards_bucket.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.landing.arn
          }
        }
      }
    ]
  })
}

module "metrics_reports_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-metrics-reports-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "interop_landing_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-landing-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
        ]
        Resource = "${module.interop_landing_bucket.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.landing.arn
          }
        }
      }
    ]
  })
}

module "public_catalog_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-public-catalog-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
        ]
        Resource = "${module.public_catalog_bucket.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.landing.arn
          }
        }
      }
    ]
  })
}

module "privacy_notices_history_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-privacy-notices-history-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        # TODO: use conditional version below when ready to lock
        # mode  = var.env == "prod" ? "COMPLIANCE" : "GOVERNANCE"
        mode  = "GOVERNANCE"
        years = 10
      }
    }
  }
}

module "privacy_notices_content_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-privacy-notices-content-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

# TODO: refactor this bucket, the contents can be exposed by other AWS services
module "public_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-%s-public-es1", var.short_name, var.env)

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  versioning = {
    enabled = true
  }

  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://${local.frontend_env_cors_domain}"]
    }
  ]

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
        ]
        Resource = "${module.public_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}

module "alb_logs_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-alb-logs-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id         = "TransitionToStandardIA"
      enabled    = true
      transition = { days = 30, storage_class = "STANDARD_IA" }
    }
  ]

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "AWS" = "arn:aws:iam::635631232127:root" # ELB account id for eu-south-1. See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
        }
        Action   = "s3:PutObject"
        Resource = "${module.alb_logs_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}

module "anac_sftp_bucket" {
  count = local.deploy_anac_sftp ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-anac-sftp-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "ivass_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.8.2"

  bucket = format("%s-ivass-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "s3_batch_reports_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-s3-batch-reports-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "data_preparation_bucket" {
  count = var.env == "dev" || var.env == "qa" || var.env == "vapt" ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.14.1"

  bucket = format("%s-data-preparation-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "frontend_additional_assets_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.14.1"

  bucket = format("%s-frontend-additional-assets-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "application_import_export_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.14.1"

  bucket = format("%s-application-import-export-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT"]
      allowed_origins = [format("https://%s", module.interop_selfcare_domain.apigw_custom_domain_name)]
    }
  ]

  lifecycle_rule = [
    {
      id         = "Expiration"
      enabled    = true
      expiration = { days : 15 }
    }
  ]
}

module "datalake_interface_export_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.14.1"

  bucket = format("%s-datalake-interface-export-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

locals {
  apigw_openapi_bucket_id = format("%s-apigw-openapi-%s-es1", local.project, var.env)
}

module "apigw_openapi_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = local.apigw_openapi_bucket_id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }
}

module "public_assets_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = format("%s-public-assets-%s", local.project, var.env)

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  attach_public_policy = true
  attach_policy        = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${module.public_assets_bucket.s3_bucket_arn}/*"
      }
    ]
  })

  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://developer.pagopa.it", "https://dev.developer.pagopa.it"]
    }
  ]

  versioning = {
    enabled = true
  }
}

module "domain_events_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-domain-events-%s-es1", var.short_name, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  lifecycle_rule = [
    {
      id      = "StandardIARule"
      enabled = true
      transition = {
        days : 30
        storage_class : "STANDARD_IA"
      }
    }
  ]
}

module "signed_domain_events_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  bucket = format("%s-signed-domain-events-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode  = var.env == "prod" ? "COMPLIANCE" : "GOVERNANCE"
        years = 10
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "StandardIARule"
      enabled = true
      transition = {
        days : 30
        storage_class : "STANDARD_IA"
      }
    }
  ]
}

module "signed_application_documents_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  bucket = format("%s-signed-application-documents-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode  = var.env == "prod" ? "COMPLIANCE" : "GOVERNANCE"
        years = 10
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "StandardIARule"
      enabled = true
      transition = {
        days : 30
        storage_class : "STANDARD_IA"
      }
    }
  ]
}

module "signed_jwt_audit_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.11.0"

  bucket = format("%s-signed-jwt-audit-%s-es1", local.project, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode  = var.env == "prod" ? "COMPLIANCE" : "GOVERNANCE"
        years = 10
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "StandardIARule"
      enabled = true
      transition = {
        days : 30
        storage_class : "STANDARD_IA"
      }
    }
  ]
}
