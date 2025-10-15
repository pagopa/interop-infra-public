resource "aws_kms_key" "interop" {
  customer_master_key_spec = "RSA_2048"
  key_usage                = "SIGN_VERIFY"
  policy = jsonencode(
    {
      Id = "DefaultPolicy"
      Statement = [
        {
          Action = "kms:*"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          }
          Resource = "*"
          Sid      = "EnableIAMPolicies"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_kms_alias" "interop" {
  name          = "alias/interop-rsa2048-${var.env}"
  target_key_id = aws_kms_key.interop.key_id
}
