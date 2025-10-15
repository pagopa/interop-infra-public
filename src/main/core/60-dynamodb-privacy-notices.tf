resource "aws_dynamodb_table" "privacy_notices" {
  name         = format("interop-privacy-notices-%s", var.env)
  billing_mode = "PAY_PER_REQUEST"


  dynamic "import_table" {
    for_each = var.env == "prod" ? [true] : []

    content {

      input_compression_type = "GZIP"
      input_format           = "DYNAMODB_JSON"

      s3_bucket_source {
        bucket     = "interop-dynamodb-exports-${var.env}"
        key_prefix = "eu-central-1/interop-privacy-notices-${var.env}/AWSDynamoDB/01728134306185-ccc0e765/data"
      }
    }
  }

  hash_key = "privacyNoticeId"

  attribute {
    name = "privacyNoticeId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "privacy_notices_acceptances" {
  name         = format("interop-privacy-notices-acceptances-%s", var.env)
  billing_mode = "PAY_PER_REQUEST"

  dynamic "import_table" {
    for_each = var.env == "prod" ? [true] : []

    content {
      input_compression_type = "GZIP"
      input_format           = "DYNAMODB_JSON"

      s3_bucket_source {
        bucket     = "interop-dynamodb-exports-${var.env}"
        key_prefix = "eu-central-1/interop-privacy-notices-acceptances-${var.env}/AWSDynamoDB/01728134284566-299cab11/data"
      }
    }
  }

  hash_key  = "pnIdWithUserId"
  range_key = "versionNumber"

  attribute {
    name = "pnIdWithUserId"
    type = "S"
  }

  attribute {
    name = "versionNumber"
    type = "N"
  }
}
