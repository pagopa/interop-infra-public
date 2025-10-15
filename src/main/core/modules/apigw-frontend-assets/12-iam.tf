data "aws_s3_bucket" "privacy_notices" {
  bucket = var.privacy_notices_bucket_name
}

data "aws_s3_bucket" "frontend_additional_assets" {
  bucket = var.frontend_additional_assets_bucket_name
}

data "aws_iam_policy_document" "apigw_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigw_frontend_additional_assets" {
  name               = format("interop-%s-apigw-frontend-assets-%s", var.api_name, var.env)
  assume_role_policy = data.aws_iam_policy_document.apigw_assume.json

  inline_policy {
    name = "GetFrontendAdditionalAssets"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "${data.aws_s3_bucket.privacy_notices.arn}/*",
          "${data.aws_s3_bucket.frontend_additional_assets.arn}/*"
        ]
      }]
    })
  }
}