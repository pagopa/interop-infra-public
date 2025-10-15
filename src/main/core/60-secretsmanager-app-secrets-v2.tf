resource "aws_secretsmanager_secret" "debezium_credentials" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = "platform-data-debezium-credentials"
}

resource "aws_secretsmanager_secret" "anac" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/anac"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "anac"
    }
  )
}

resource "aws_secretsmanager_secret" "selfcare_v2" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/selfcare-v2"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "selfcare-v2"
    }
  )
}

resource "aws_secretsmanager_secret" "postgres" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/postgres"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "postgres"
    }
  )
}

resource "aws_secretsmanager_secret" "documentdb" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/documentdb"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "documentdb"
    }
  )
}

resource "aws_secretsmanager_secret" "metrics_reports" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/metrics-reports"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "metrics-reports"
    }
  )
}

resource "aws_secretsmanager_secret" "smtp_reports" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/smtp-reports"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "smtp-reports"
    }
  )
}

resource "aws_secretsmanager_secret" "pn_consumers" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/pn-consumers"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "pn-consumers"
    }
  )
}

resource "aws_secretsmanager_secret" "onetrust" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/onetrust"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "onetrust"
    }
  )
}

resource "aws_secretsmanager_secret" "smtp_certified" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/smtp-certified"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "smtp-certified"
    }
  )
}

resource "aws_secretsmanager_secret" "support_saml" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/support-saml"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "support-saml"
    }
  )
}

resource "aws_secretsmanager_secret" "event_store" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/event-store"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "event-store"
    }
  )
}

resource "aws_secretsmanager_secret" "read_model" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/read-model"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "read-model"
    }
  )
}

resource "aws_secretsmanager_secret" "smtp_notifications" {
  count = local.deployment_repo_v2_active ? 1 : 0

  name = "app/backend/smtp-notifications"

  tags = merge(local.eks_secret_default_tags,
    {
      EKSReplicaSecretName = "smtp-notifications"
    }
  )
}
