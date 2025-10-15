terraform {
  required_version = "~> 1.8.0"

  # uncomment when the resources in this file are deployed
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy" "admin_access" {
  name = "AdministratorAccess"

}

data "aws_iam_policy" "readonly_access" {
  name = "ReadOnlyAccess"
}

# terraform state file setup
# create an S3 bucket to store the state file in

resource "aws_s3_bucket" "terraform_states" {
  bucket = format("terraform-backend-%s", data.aws_caller_identity.current.account_id)

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    name = "S3 Remote Terraform State Store"
  })
}

resource "aws_s3_bucket_public_access_block" "terraform_states" {
  bucket                  = aws_s3_bucket.terraform_states.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_states" {
  bucket = aws_s3_bucket.terraform_states.id
  versioning_configuration {
    status = "Enabled"
  }
}

# create a DynamoDB table for locking the state file
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-lock"
  hash_key       = "LockID"
  read_capacity  = 4
  write_capacity = 4

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(var.tags, {
    name = "DynamoDB Terraform State Lock Table"
  })

}
