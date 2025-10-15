locals {
  be_iam_prefix = "${local.project}-be"
}


module "be_refactor_debezium_postgresql_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-debezium-postgresql-%s-es1", local.project, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  max_session_duration = 43200

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:debezium-postgresql"]
    }
  }

  role_policy_arns = {
    be_refactor_debezium_postgresql = aws_iam_policy.be_refactor_debezium_postgresql[0].arn
  }
}

module "attribute_registry_process_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-attribute-registry-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = var.env == "dev" ? ["${local.k8s_namespace_irsa}:interop-be-attribute-registry-process*"] : ["${local.k8s_namespace_irsa}:interop-be-attribute-registry-process"]
    }
  }

  role_policy_arns = {
    be_attribute_registry_process = aws_iam_policy.be_attribute_registry_process[0].arn
  }
}

module "be_authorization_process_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-authorization-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = var.env == "dev" ? ["${local.k8s_namespace_irsa}:interop-be-authorization-process*"] : ["${local.k8s_namespace_irsa}:interop-be-authorization-process"]
    }
  }

  role_policy_arns = {
    be_authorization_process = aws_iam_policy.be_authorization_process[0].arn
  }
}

module "be_refactor_catalog_process_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-catalog-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = var.env == "dev" ? ["${local.k8s_namespace_irsa}:interop-be-catalog-process*"] : ["${local.k8s_namespace_irsa}:interop-be-catalog-process"]
    }
  }

  role_policy_arns = {
    be_refactor_catalog_process = aws_iam_policy.be_refactor_catalog_process[0].arn
  }
}

module "be_refactor_catalog_outbound_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-catalog-outbound-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-catalog-outbound-writer"]
    }
  }

  role_policy_arns = {
    be_refactor_catalog_outbound_writer = aws_iam_policy.be_refactor_catalog_outbound_writer[0].arn
  }
}

module "be_refactor_catalog_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-catalog-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-catalog-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-catalog-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_refactor_catalog_readmodel_writer = aws_iam_policy.be_refactor_catalog_readmodel_writer[0].arn
  }
}

module "be_refactor_attribute_registry_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-attribute-registry-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-attribute-registry-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-attribute-registry-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_refactor_attribute_registry_readmodel_writer = aws_iam_policy.be_refactor_attribute_registry_readmodel_writer[0].arn
  }
}

module "be_refactor_agreement_email_sender_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-agreement-email-sender-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-agreement-email-sender"]
    }
  }

  role_policy_arns = {
    be_refactor_agreement_email_sender = aws_iam_policy.be_refactor_agreement_email_sender[0].arn
    notifiche_ses_iam_policy           = module.notifiche_ses_iam_policy.iam_policy_arn
  }
}

module "be_refactor_agreement_outbound_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-agreement-outbound-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-agreement-outbound-writer"]
    }
  }

  role_policy_arns = {
    be_refactor_agreement_outbound_writer = aws_iam_policy.be_refactor_agreement_outbound_writer[0].arn
  }
}

module "be_refactor_agreement_process_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-agreement-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = var.env == "dev" ? ["${local.k8s_namespace_irsa}:interop-be-agreement-process*"] : ["${local.k8s_namespace_irsa}:interop-be-agreement-process"]
    }
  }

  role_policy_arns = {
    be_refactor_agreement_process = aws_iam_policy.be_refactor_agreement_process[0].arn
  }
}

module "be_refactor_agreement_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-agreement-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-agreement-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-agreement-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_refactor_agreement_readmodel_writer = aws_iam_policy.be_refactor_agreement_readmodel_writer[0].arn
  }
}

module "be_refactor_purpose_process_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-purpose-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = var.env == "dev" ? ["${local.k8s_namespace_irsa}:interop-be-purpose-process*"] : ["${local.k8s_namespace_irsa}:interop-be-purpose-process"]
    }
  }

  role_policy_arns = {
    be_refactor_purpose_process = aws_iam_policy.be_refactor_purpose_process[0].arn
  }
}

module "be_refactor_purpose_outbound_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-purpose-outbound-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-purpose-outbound-writer"]
    }
  }

  role_policy_arns = {
    be_refactor_purpose_outbound_writer = aws_iam_policy.be_refactor_purpose_outbound_writer[0].arn
  }
}


module "be_refactor_purpose_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-purpose-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-purpose-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-purpose-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_refactor_purpose_readmodel_writer = aws_iam_policy.be_refactor_purpose_readmodel_writer[0].arn
  }
}

module "be_refactor_client_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-client-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-client-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-client-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_refactor_client_readmodel_writer = aws_iam_policy.be_refactor_client_readmodel_writer[0].arn
  }
}

module "be_refactor_key_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-key-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-key-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-key-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_refactor_key_readmodel_writer = aws_iam_policy.be_refactor_key_readmodel_writer[0].arn
  }
}

module "be_tenant_process_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-tenant-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = var.env == "dev" ? ["${local.k8s_namespace_irsa}:interop-be-tenant-process*"] : ["${local.k8s_namespace_irsa}:interop-be-tenant-process"]
    }
  }

  role_policy_arns = {
    be_tenant_process = aws_iam_policy.be_tenant_process[0].arn
  }
}

module "be_refactor_tenant_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-tenant-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-tenant-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-tenant-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_refactor_tenant_readmodel_writer = aws_iam_policy.be_refactor_tenant_readmodel_writer[0].arn
  }
}

module "be_refactor_tenant_outbound_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-tenant-outbound-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-tenant-outbound-writer"]
    }
  }

  role_policy_arns = {
    be_refactor_tenant_outbound_writer = aws_iam_policy.be_refactor_tenant_outbound_writer[0].arn
  }
}

module "be_refactor_compute_agreements_consumer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-compute-agreements-consumer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-compute-agreements-consumer"]
    }
  }

  role_policy_arns = {
    be_refactor_compute_agreements_consumer = aws_iam_policy.be_refactor_compute_agreements_consumer[0].arn
  }
}

module "be_refactor_authorization_updater_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-authorization-updater-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-authorization-updater"]
    }
  }

  role_policy_arns = {
    be_refactor_authorization_updater = aws_iam_policy.be_refactor_authorization_updater[0].arn
  }
}

module "be_refactor_notifier_seeder_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-notifier-seeder-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-notifier-seeder"]
    }
  }

  role_policy_arns = {
    be_refactor_notifier_seeder = aws_iam_policy.be_refactor_notifier_seeder[0].arn
  }
}

module "be_refactor_producer_key_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-producer-key-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-producer-key-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-producer-key-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_refactor_producer_key_readmodel_writer = aws_iam_policy.be_refactor_producer_key_readmodel_writer[0].arn
  }
}

module "be_refactor_producer_keychain_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-producer-keychain-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-producer-keychain-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-producer-keychain-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_refactor_producer_keychain_readmodel_writer = aws_iam_policy.be_refactor_producer_keychain_readmodel_writer[0].arn
  }
}

module "be_refactor_backend_for_frontend_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-backend-for-frontend-%s-es1", local.be_iam_prefix, var.env)

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

module "be_refactor_authorization_server_irsa" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-authorization-server-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-authorization-server-node"]
    }
  }

  role_policy_arns = {
    be_authorization_server = aws_iam_policy.be_refactor_authorization_server[0].arn
  }
}

module "be_refactor_agreement_platformstate_writer_irsa" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-agreement-platformstate-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-agreement-platformstate-writer"]
    }
  }

  role_policy_arns = {
    be_agreement_platformstate_writer = aws_iam_policy.be_refactor_agreement_platformstate_writer[0].arn
  }
}

module "be_refactor_authorization_platformstate_writer_irsa" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-authorization-platformstate-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-authorization-platformstate-writer"]
    }
  }

  role_policy_arns = {
    be_authorization_platformstate_writer = aws_iam_policy.be_refactor_authorization_platformstate_writer[0].arn
  }
}

module "be_refactor_catalog_platformstate_writer_irsa" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-catalog-platformstate-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-catalog-platformstate-writer"]
    }
  }

  role_policy_arns = {
    be_catalog_platformstate_writer = aws_iam_policy.be_refactor_catalog_platformstate_writer[0].arn
  }
}

module "be_refactor_purpose_platformstate_writer_irsa" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-purpose-platformstate-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-purpose-platformstate-writer"]
    }
  }

  role_policy_arns = {
    be_purpose_platformstate_writer = aws_iam_policy.be_refactor_purpose_platformstate_writer[0].arn
  }
}

module "be_datalake_interface_exporter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-datalake-interface-exporter-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-datalake-interface-exporter"]
    }
  }

  role_policy_arns = {
    be_datalake_interface_exporter = aws_iam_policy.be_datalake_interface_exporter[0].arn
  }
}

module "be_delegation_items_archiver_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-delegation-items-archiver-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-delegation-items-archiver"]
    }
  }

  role_policy_arns = {
    be_delegation_items_archiver = aws_iam_policy.be_delegation_items_archiver[0].arn
  }
}

module "be_delegation_readmodel_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-delegation-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-delegation-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-delegation-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_delegation_readmodel_writer = aws_iam_policy.be_delegation_readmodel_writer[0].arn
  }
}

module "be_delegation_process_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-delegation-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-delegation-process"]
    }
  }

  role_policy_arns = {
    be_delegation_process = aws_iam_policy.be_delegation_process[0].arn
  }
}

module "be_refactor_token_details_persister_irsa" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-token-details-persister-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-token-details-persister-node"]
    }
  }

  role_policy_arns = {
    be_refactor_token_details_persister = aws_iam_policy.be_refactor_token_details_persister[0].arn
  }
}

module "be_client_purpose_updater_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-client-purpose-updater-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-client-purpose-updater"]
    }
  }

  role_policy_arns = {
    be_client_purpose_updater = aws_iam_policy.be_client_purpose_updater[0].arn
  }
}

module "be_delegation_outbound_writer_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-delegation-outbound-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-delegation-outbound-writer"]
    }
  }

  role_policy_arns = {
    be_delegation_outbound_writer = aws_iam_policy.be_delegation_outbound_writer[0].arn
  }
}

module "be_refactor_token_generation_readmodel_checker_irsa" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-token-generation-readmodel-checker-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-token-generation-readmodel-checker"]
    }
  }

  role_policy_arns = {
    be_refactor_token_generation_readmodel_checker = aws_iam_policy.be_refactor_token_generation_readmodel_checker[0].arn
  }
}

module "be_ipa_certified_attributes_importer_irsa" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-ipa-certified-attributes-importer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-ipa-certified-attributes-importer"]
    }
  }

  role_policy_arns = {
    be_ipa_certified_attributes_importer = aws_iam_policy.be_ipa_certified_attributes_importer[0].arn
  }
}

module "be_refactor_api_gateway_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-api-gateway-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = var.env == "dev" ? ["${local.k8s_namespace_irsa}:interop-be-api-gateway*"] : ["${local.k8s_namespace_irsa}:interop-be-api-gateway"]
    }
  }

  role_policy_arns = {
    be_api_gatewaay = aws_iam_policy.be_api_gateway[0].arn
  }
}

module "be_eservice_template_process_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-eservice-template-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-eservice-template-process"]
    }
  }

  role_policy_arns = {
    be_eservice_template_process = aws_iam_policy.be_eservice_template_process[0].arn
  }
}

module "be_eservice_template_readmodel_writer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-eservice-template-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "${local.k8s_namespace_irsa}:interop-be-eservice-template-readmodel-writer",
        "${local.k8s_namespace_irsa}:interop-be-eservice-template-readmodel-writer-sql"
      ]
    }
  }

  role_policy_arns = {
    be_eservice_template_readmodel_writer = aws_iam_policy.be_eservice_template_readmodel_writer[0].arn
  }
}

module "be_eservice_template_instances_updater_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-eservice-template-instances-updater-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-eservice-template-instances-updater"]
    }
  }

  role_policy_arns = {
    be_eservice_template_instances_updater = aws_iam_policy.be_eservice_template_instances_updater[0].arn
  }
}

module "be_eservice_template_outbound_writer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-eservice-template-outbound-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-eservice-template-outbound-writer"]
    }
  }

  role_policy_arns = {
    be_refactor_eservice_template_outbound_writer = aws_iam_policy.be_refactor_eservice_template_outbound_writer[0].arn
  }
}

module "be_notification_email_sender_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-notification-email-sender-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-notification-email-sender"]
    }
  }

  role_policy_arns = {
    be_notification_email_sender = aws_iam_policy.be_notification_email_sender[0].arn
    notifiche_ses_iam_policy     = module.notifiche_ses_iam_policy.iam_policy_arn
  }
}

module "be_certified_email_sender_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-certified-email-sender-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-certified-email-sender"]
    }
  }

  role_policy_arns = {
    be_certified_email_sender = aws_iam_policy.be_certified_email_sender[0].arn
  }
}

module "be_m2m_gateway_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-m2m-gateway-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-m2m-gateway"]
    }
  }

  role_policy_arns = {
    be_m2m_gateway = aws_iam_policy.be_m2m_gateway[0].arn
  }
}

module "be_selfcare_client_users_updater_irsa" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-selfcare-client-users-updater-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-selfcare-client-users-updater"]
    }
  }

  role_policy_arns = {
    be_selfcare_client_users_updater = aws_iam_policy.be_selfcare_client_users_updater[0].arn
  }
}

module "be_audit_signer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-audit-signer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-audit-signer"]
    }
  }

  role_policy_arns = {
    be_audit_signer = aws_iam_policy.be_audit_signer.arn
  }
}

module "be_documents_generator_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-documents-generator-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-documents-generator"]
    }
  }

  role_policy_arns = {
    be_documents_generator = aws_iam_policy.be_documents_generator.arn
  }
}

module "be_documents_signer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-documents-signer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-documents-signer"]
    }
  }

  role_policy_arns = {
    be_documents_signer = aws_iam_policy.be_documents_signer.arn
  }
}

module "be_events_signer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("%s-events-signer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-events-signer"]
    }
  }

  role_policy_arns = {
    be_events_signer = aws_iam_policy.be_events_signer.arn
  }
}

module "be_purpose_template_process_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-purpose-template-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-purpose-template-process"]
    }
  }

  role_policy_arns = {
    be_purpose_template_process = aws_iam_policy.be_purpose_template_process[0].arn
  }
}

module "be_purpose_template_readmodel_writer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-purpose-template-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-purpose-template-readmodel-writer-sql"]
    }
  }

  role_policy_arns = {
    be_purpose_template_readmodel_writer = aws_iam_policy.be_purpose_template_readmodel_writer[0].arn
  }
}

module "be_notification_config_process_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-notification-config-process-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-notification-config-process"]
    }
  }

  role_policy_arns = {
    be_notification_config_process = aws_iam_policy.be_notification_config_process[0].arn
  }
}

module "be_notification_config_readmodel_writer_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-notification-config-readmodel-writer-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-notification-config-readmodel-writer-sql"]
    }
  }

  role_policy_arns = {
    be_notification_config_readmodel_writer = aws_iam_policy.be_notification_config_readmodel_writer[0].arn
  }
}

module "be_in_app_notification_manager_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.18.0"

  role_name = format("%s-in-app-notification-manager-%s-es1", local.be_iam_prefix, var.env)

  assume_role_condition_test = var.env == "dev" ? "StringLike" : "StringEquals"

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.k8s_namespace_irsa}:interop-be-in-app-notification-manager"]
    }
  }

  role_policy_arns = {
    be_in_app_notification_manager = aws_iam_policy.be_in_app_notification_manager[0].arn
  }
}
