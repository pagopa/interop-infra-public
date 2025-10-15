locals {
  role_prefix = format("interop-iam-service-%s", var.env)

  # workaround to allow both 'dev' and 'dev-refactor'
  k8s_namespace_irsa = var.env == "dev" ? "dev*" : var.env
}

module "be_agreement_management_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-agreement-management-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-agreement-management"]
    }
  }

  role_policy_arns = {
    be_agreement_management = aws_iam_policy.be_agreement_management.arn
  }
}

module "be_authorization_management_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-authorization-management-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-authorization-management"]
    }
  }

  role_policy_arns = {
    be_authorization_management = aws_iam_policy.be_authorization_management.arn
  }
}

module "be_agreement_process_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-agreement-process-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-agreement-process"]
    }
  }

  role_policy_arns = {
    be_agreement_process = aws_iam_policy.be_agreement_process.arn
  }
}

module "be_catalog_management_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-catalog-management-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-catalog-management"]
    }
  }

  role_policy_arns = {
    be_catalog_management = aws_iam_policy.be_catalog_management.arn
  }
}

module "be_authorization_server_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-authorization-server-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-authorization-server"]
    }
  }

  role_policy_arns = {
    be_authorization_server = aws_iam_policy.be_authorization_server.arn
  }
}

module "be_catalog_process_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-catalog-process-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-catalog-process"]
    }
  }

  role_policy_arns = {
    be_catalog_proces = aws_iam_policy.be_catalog_process.arn
  }
}

module "be_purpose_management_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-purpose-management-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-purpose-management"]
    }
  }

  role_policy_arns = {
    be_purpose_management = aws_iam_policy.be_purpose_management.arn
  }
}

module "be_notifier_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-notifier-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-notifier"]
    }
  }

  role_policy_arns = {
    be_notifier = aws_iam_policy.be_notifier.arn
  }
}

module "be_purpose_process_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-purpose-process-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-purpose-process"]
    }
  }

  role_policy_arns = {
    be_purpose_process = aws_iam_policy.be_purpose_process.arn
  }
}

module "be_backend_for_frontend_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-backend-for-frontend-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-backend-for-frontend"]
    }
  }

  role_policy_arns = {
    be_backend_for_frontend = aws_iam_policy.be_backend_for_frontend.arn
  }
}

module "be_selfcare_onboarding_consumer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-selfcare-onboarding-consumer-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-selfcare-onboarding-consumer"]
    }
  }

  role_policy_arns = {
    be_selfcare_onboarding_consumer = aws_iam_policy.be_selfcare_onboarding_consumer.arn
  }
}

module "be_anac_certified_attributes_importer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-anac-certified-attributes-importer-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-anac-certified-attributes-importer"]
    }
  }

  role_policy_arns = {
    be_anac_certified_attributes_importer = aws_iam_policy.be_anac_certified_attributes_importer.arn
  }
}

module "be_ivass_certified_attributes_importer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("interop-be-ivass-certified-attributes-importer-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-ivass-certified-attributes-importer"]
    }
  }

  role_policy_arns = {
    be_ivass_certified_attributes_importer = aws_iam_policy.be_ivass_certified_attributes_importer.arn
  }
}

module "be_attributes_loader_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-attributes-loader-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-attributes-loader"]
    }
  }

  role_policy_arns = {
    be_attributes_loader = aws_iam_policy.be_attributes_loader.arn
  }
}

module "be_token_details_persister_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-token-details-persister-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-token-details-persister"]
    }
  }

  role_policy_arns = {
    be_token_details_persister = aws_iam_policy.be_token_details_persister.arn
  }
}

module "be_tenants_certified_attributes_updater_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-tenants-cert-attr-updater-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-tenants-cert-attr-updater"]
    }
  }

  role_policy_arns = {
    be_tenants_certified_attributes_updater = aws_iam_policy.be_tenants_certified_attributes_updater.arn
  }
}

module "be_party_registry_refresher_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-interop-be-party-registry-refresher-es1", local.role_prefix)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-party-registry-refresher"]
    }
  }
}

module "be_metrics_report_generator_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-metrics-report-generator-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-metrics-report-generator"]
    }
  }

  role_policy_arns = {
    be_metrics_report_generator = aws_iam_policy.be_metrics_report_generator.arn
  }
}

module "be_pa_digitale_report_generator_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-padigitale-report-generator-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-padigitale-report-generator"]
    }
  }

  role_policy_arns = {
    be_pa_digitale_report_generator = aws_iam_policy.be_pa_digitale_report_generator.arn
  }
}

module "be_dashboard_metrics_report_generator_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-dashboard-metrics-report-generator-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-dashboard-metrics-report-generator"]
    }
  }

  role_policy_arns = {
    be_dashboard_metrics_report_generator = aws_iam_policy.be_dashboard_metrics_report_generator.arn
  }
}

module "be_dtd_catalog_exporter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-dtd-catalog-exporter-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-dtd-catalog-exporter"]
    }
  }

  role_policy_arns = {
    be_dtd_catalog_exporter = aws_iam_policy.be_dtd_catalog_exporter.arn
  }
}

module "be_privacy_notices_updater_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-privacy-notices-updater-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-privacy-notices-updater"]
    }
  }

  role_policy_arns = {
    be_privacy_notices_updater = aws_iam_policy.be_privacy_notices_updater.arn
  }
}

module "be_one_trust_notices_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-one-trust-notices-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-one-trust-notices"]
    }
  }

  role_policy_arns = {
    be_one_trust_notices = aws_iam_policy.be_one_trust_notices.arn
  }
}

module "be_purposes_archiver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-purposes-archiver-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-purposes-archiver"]
    }
  }

  role_policy_arns = {
    be_purposes_archiver = aws_iam_policy.be_purposes_archiver.arn
  }
}

module "be_eservice_descriptors_archiver_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-eservice-descriptors-archiver-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = var.env == "dev" ? ["${local.k8s_namespace_irsa}:interop-be-eservice-descriptors-archiver*"] : ["${local.k8s_namespace_irsa}:interop-be-eservice-descriptors-archiver"]
    }
  }

  role_policy_arns = merge({
    be_eservice_descriptors_archiver = aws_iam_policy.be_eservice_descriptors_archiver.arn

    },
    local.deploy_be_refactor_infra ? { be_refactor = aws_iam_policy.be_refactor_eservice_descriptors_archiver[0].arn }
  : {})
}

module "be_dtd_metrics_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-dtd-metrics-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-dtd-metrics"]
    }
  }

  role_policy_arns = {
    be_dtd_metrics = aws_iam_policy.be_dtd_metrics.arn
  }
}

module "be_datalake_data_export_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-datalake-data-export-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-datalake-data-export"]
    }
  }

  role_policy_arns = {
    be_datalake_data_export = aws_iam_policy.be_datalake_data_export.arn
  }
}

module "be_pn_consumers_irsa_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("interop-be-pn-consumers-%s-es1", var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-pn-consumers"]
    }
  }

  role_policy_arns = {
    be_pn_consumers = module.reports_ses_iam_policy.iam_policy_arn
  }
}
