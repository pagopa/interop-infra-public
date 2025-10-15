data "aws_iam_policy_document" "github_monorepo_assume" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:pagopa/interop-kpi:*",
      ]
    }
  }
}

resource "aws_iam_role" "github_monorepo" {
  depends_on = [aws_ecr_repository.app]

  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  name = format("%s-kpi-github-monorepo-%s", local.project, var.env)

  assume_role_policy = data.aws_iam_policy_document.github_monorepo_assume[0].json

  inline_policy {
    name = "GithubEcrPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "ecr:GetAuthorizationToken"
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ecr:CompleteLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:InitiateLayerUpload",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:BatchGetImage"
          ]
          Resource = [
            for repo in values(aws_ecr_repository.app) : repo.arn
          ]
        }
      ]
    })
  }
}