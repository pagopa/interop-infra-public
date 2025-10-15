locals {
  be_iam_prefix = "interop-be"
}

module "be_jwt_audit_analytics_writer_irsa" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.20.0"
  role_name = format("%s-jwt-audit-analytics-writer-%s", local.be_iam_prefix, var.env)
  oidc_providers = {
    cluster = {
      provider_arn               = data.aws_iam_openid_connect_provider.core_eks.arn
      namespace_service_accounts = ["${var.analytics_k8s_namespace}:interop-be-jwt-audit-analytics-writer"]
    }
  }

  role_policy_arns = {
    be_jwt_audit_analytics_writer = aws_iam_policy.be_jwt_audit_analytics_writer[0].arn
  }
}

module "be_domains_analytics_writer_irsa" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.20.0"
  role_name = format("%s-domains-analytics-writer-%s", local.be_iam_prefix, var.env)
  oidc_providers = {
    cluster = {
      provider_arn               = data.aws_iam_openid_connect_provider.core_eks.arn
      namespace_service_accounts = ["${var.analytics_k8s_namespace}:interop-be-domains-analytics-writer"]
    }
  }

  role_policy_arns = {
    be_domains_analytics_writer = aws_iam_policy.be_domains_analytics_writer[0].arn
  }
}

resource "aws_iam_role_policy_attachment" "application_audit_producers" {
  for_each = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? toset(var.application_audit_producers_irsa_list) : []

  role       = data.aws_iam_role.application_audit_producers[each.key].name
  policy_arn = aws_iam_policy.application_audit[0].arn
}

module "be_alb_logs_analytics_writer_irsa" {
  count = local.deploy_all_data_ingestion_resources ? 1 : 0

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.20.0"
  role_name = format("%s-alb-logs-analytics-writer-%s", local.be_iam_prefix, var.env)
  oidc_providers = {
    cluster = {
      provider_arn               = data.aws_iam_openid_connect_provider.core_eks.arn
      namespace_service_accounts = ["${var.analytics_k8s_namespace}:interop-be-alb-logs-analytics-writer"]
    }
  }

  role_policy_arns = {
    be_alb_logs_analytics_writer = aws_iam_policy.be_alb_logs_analytics_writer[0].arn
  }
}

module "be_application_audit_archiver_irsa" {
  count = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? 1 : 0

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.20.0"
  role_name = format("%s-application-audit-archiver-%s", local.be_iam_prefix, var.env)
  oidc_providers = {
    cluster = {
      provider_arn               = data.aws_iam_openid_connect_provider.core_eks.arn
      namespace_service_accounts = ["${var.analytics_k8s_namespace}:interop-be-application-audit-archiver"]
    }
  }

  role_policy_arns = {
    be_application_audit_archiver = aws_iam_policy.be_application_audit_archiver[0].arn
  }
}

module "be_application_audit_analytics_writer_irsa" {
  count = local.deploy_all_data_ingestion_resources || local.deploy_only_application_audit_resources ? 1 : 0

  source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version   = "5.20.0"
  role_name = format("%s-application-audit-analytics-writer-%s", local.be_iam_prefix, var.env)
  oidc_providers = {
    cluster = {
      provider_arn               = data.aws_iam_openid_connect_provider.core_eks.arn
      namespace_service_accounts = ["${var.analytics_k8s_namespace}:interop-be-application-audit-analytics-writer"]
    }
  }

  role_policy_arns = {
    be_application_audit_analytics_writer = aws_iam_policy.be_application_audit_analytics_writer[0].arn
  }
}
