locals {
  msk_iam_prefix = "arn:aws:kafka:${var.aws_region}:${data.aws_caller_identity.current.account_id}"

  platform_events_cluster_name = (local.deploy_be_refactor_infra ?
  aws_msk_cluster.platform_events[0].cluster_name : null)

  platform_events_cluster_uuid = (local.deploy_be_refactor_infra ?
  split("/", aws_msk_cluster.platform_events[0].arn)[2] : null)
  debezium_event_store_offsets_topic = "debezium.event-store.offsets"

  msk_topic_iam_prefix = (local.deploy_be_refactor_infra
    ? "${local.msk_iam_prefix}:topic/${local.platform_events_cluster_name}/${local.platform_events_cluster_uuid}"
  : null)
  msk_group_iam_prefix = (local.deploy_be_refactor_infra
    ? "${local.msk_iam_prefix}:group/${local.platform_events_cluster_name}/${local.platform_events_cluster_uuid}"
  : null)

  project_titled = title(local.project)
}

resource "aws_iam_policy" "be_refactor_debezium_postgresql" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = "DebeziumPostgresqlPolicyEs1"

  policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:CreateTopic",
          "kafka-cluster:DescribeCluster",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:DescribeTopicDynamicConfiguration",
          "kafka-cluster:AlterTopicDynamicConfiguration",
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/__*debezium.*",
          "${local.msk_topic_iam_prefix}/event-store.*",
          "${local.msk_group_iam_prefix}/*debezium.*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = aws_secretsmanager_secret.debezium_credentials[0].arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_attribute_registry_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeAttributeRegistryProcessPolicyEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_api_gateway" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeApiGatewayPolicyEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_m2m_gateway" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeM2MGatewayEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)
      },
      {
        Sid    = "ReadSignedObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          format("%s/*", module.signed_jwt_audit_bucket.s3_bucket_arn),
          format("%s/*", module.signed_application_documents_bucket.s3_bucket_arn),
          format("%s/*", module.signed_domain_events_bucket.s3_bucket_arn),
        ]
      },
    ]
  })
}

resource "aws_iam_policy" "be_authorization_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeAuthorizationProcessPolicyEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_catalog_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeCatalogProcessRefactorPolicyEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)

      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_catalog_outbound_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeCatalogOutboundWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_catalog.events",
          "${local.msk_group_iam_prefix}/*catalog-outbound-writer"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/outbound.*_catalog.events",
          "${local.msk_group_iam_prefix}/*catalog-outbound-writer"
        ]
      }
    ]
  })
}

# TODO: refactor Kafka policies to be reusable
resource "aws_iam_policy" "be_refactor_catalog_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeCatalogReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_catalog.events",
          "${local.msk_group_iam_prefix}/*catalog-readmodel-writer",
          "${local.msk_group_iam_prefix}/*catalog-readmodel-writer-sql"
        ]
      }
    ]
  })
}

# TODO: refactor Kafka policies to be reusable
resource "aws_iam_policy" "be_refactor_attribute_registry_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeAttributeRegistryReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_attribute_registry.events",
          "${local.msk_group_iam_prefix}/*attribute-registry-readmodel-writer",
          "${local.msk_group_iam_prefix}/*attribute-registry-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_agreement_email_sender" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeAgreementEmailSenderEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_group_iam_prefix}/*agreement-email-sender"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_agreement_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeAgreementProcessRefactorPolicyEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)

      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = module.persistence_events_queue.queue_arn
      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = module.certified_mail_queue.queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_agreement_outbound_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeAgreementOutboundWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_group_iam_prefix}/*agreement-outbound-writer"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/outbound.*_agreement.events",
          "${local.msk_group_iam_prefix}/*agreement-outbound-writer"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_agreement_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeAgreementReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_group_iam_prefix}/*agreement-readmodel-writer",
          "${local.msk_group_iam_prefix}/*agreement-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_eservice_descriptors_archiver" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeEserviceDescriptorsArchiverEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_group_iam_prefix}/*eservice-descriptors-archiver"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_purpose_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBePurposeProcessRefactorPolicyEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)
      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = module.persistence_events_queue.queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_purpose_outbound_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBePurposeOutboundWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_purpose.events",
          "${local.msk_group_iam_prefix}/*purpose-outbound-writer"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/outbound.*_purpose.events",
          "${local.msk_group_iam_prefix}/*purpose-outbound-writer"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_purpose_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBePurposeReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_purpose.events",
          "${local.msk_group_iam_prefix}/*purpose-readmodel-writer",
          "${local.msk_group_iam_prefix}/*purpose-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_client_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeClientReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_authorization.events",
          "${local.msk_group_iam_prefix}/*client-readmodel-writer",
          "${local.msk_group_iam_prefix}/*client-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_key_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeKeyReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_authorization.events",
          "${local.msk_group_iam_prefix}/*key-readmodel-writer",
          "${local.msk_group_iam_prefix}/*key-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_tenant_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeTenantProcessPolicyEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_tenant_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeTenantReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_tenant.events",
          "${local.msk_group_iam_prefix}/*tenant-readmodel-writer",
          "${local.msk_group_iam_prefix}/*tenant-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_tenant_outbound_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeTenantOutboundWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_tenant.events",
          "${local.msk_group_iam_prefix}/*tenant-outbound-writer"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/outbound.*_tenant.events",
          "${local.msk_group_iam_prefix}/*purpose-outbound-writer"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_compute_agreements_consumer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeComputeAgreementsConsumerEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_tenant.events",
          "${local.msk_group_iam_prefix}/*compute-agreements-consumer"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_authorization_updater" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeAuthorizationUpdaterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_catalog.events",
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_topic_iam_prefix}/event-store.*_purpose.events",
          "${local.msk_topic_iam_prefix}/event-store.*_authorization.events",
          "${local.msk_group_iam_prefix}/*authorization-updater"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_notifier_seeder" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeNotifierSeederEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_catalog.events",
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_topic_iam_prefix}/event-store.*_purpose.events",
          "${local.msk_topic_iam_prefix}/event-store.*_authorization.events",
          "${local.msk_group_iam_prefix}/*notifier-seeder"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage",
        Resource = module.persistence_events_queue.queue_arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_producer_key_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeProducerKeyReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_authorization.events",
          "${local.msk_group_iam_prefix}/*producer-key-readmodel-writer",
          "${local.msk_group_iam_prefix}/*producer-key-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_producer_keychain_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeProducerKeychainReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_authorization.events",
          "${local.msk_group_iam_prefix}/*producer-keychain-readmodel-writer",
          "${local.msk_group_iam_prefix}/*producer-keychain-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_authorization_server" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%sBeRefactorAuthorizationServerPolicyEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBTokenGenerationStates"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.token_generation_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.token_generation_states[0].arn)
        ]
      },
      {
        Sid    = "DynamoDBDpopCache"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.dpop_cache[0].arn,
        ]
      },
      {
        Sid      = "KMSGenerateToken"
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      },
      {
        Sid      = "S3WriteJWTAuditFallback"
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = format("%s/*", module.generated_jwt_details_fallback_bucket.s3_bucket_arn)
      },
      {
        Sid    = "MSKWriteJWTAudit"
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_authorization-server.generated-jwt",
          "${local.msk_group_iam_prefix}/*-authorization-server"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_agreement_platformstate_writer" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%sBeAgreementPlatformStateWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MSKAgreementEvents"
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_group_iam_prefix}/*-agreement-platformstate-writer"
        ]
      },
      {
        Sid    = "DynamoDBPlatformStates"
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.platform_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.platform_states[0].arn)
        ]
      },
      {
        Sid    = "DynamoDBTokenGenStates"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.token_generation_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.token_generation_states[0].arn)
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_authorization_platformstate_writer" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%sBeAuthorizationPlatformStateWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MSKAgreementEvents"
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_authorization.events",
          "${local.msk_group_iam_prefix}/*-authorization-platformstate-writer"
        ]
      },
      {
        Sid    = "DynamoDBPlatformStates"
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.platform_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.platform_states[0].arn)
        ]
      },
      {
        Sid    = "DynamoDBTokenGenStates"
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.token_generation_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.token_generation_states[0].arn)
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_catalog_platformstate_writer" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%sBeCatalogPlatformStateWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MSKAgreementEvents"
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_catalog.events",
          "${local.msk_group_iam_prefix}/*-catalog-platformstate-writer"
        ]
      },
      {
        Sid    = "DynamoDBPlatformStates"
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.platform_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.platform_states[0].arn),
        ]
      },
      {
        Sid    = "DynamoDBTokenGenStates"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.token_generation_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.token_generation_states[0].arn),
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_purpose_platformstate_writer" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%sBePurposePlatformStateWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MSKAgreementEvents"
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_purpose.events",
          "${local.msk_group_iam_prefix}/*-purpose-platformstate-writer"
        ]
      },
      {
        Sid    = "DynamoDBPlatformStates"
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.platform_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.platform_states[0].arn),
        ]
      },
      {
        Sid    = "DynamoDBTokenGenStates"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.token_generation_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.token_generation_states[0].arn),
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_datalake_interface_exporter" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeDataLakeInterfaceExporterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_catalog.events",
          "${local.msk_group_iam_prefix}/*datalake-interface-exporter"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
        ]
        Resource = format("%s/*", module.datalake_interface_export_bucket.s3_bucket_arn)
      }
    ]
  })
}

resource "aws_iam_policy" "be_delegation_items_archiver" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeDelegationItemsArchiverEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_delegation.events",
          "${local.msk_group_iam_prefix}/*delegation-items-archiver"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_delegation_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeDelegationReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_delegation.events",
          "${local.msk_group_iam_prefix}/*delegation-readmodel-writer",
          "${local.msk_group_iam_prefix}/*delegation-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_delegation_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeDelegationProcessPolicyEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [format("%s/*", module.application_documents_bucket.s3_bucket_arn)]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_token_details_persister" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%sBeTokenDetailsPersisterRefactorEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_authorization-server.generated-jwt",
          "${local.msk_group_iam_prefix}/*token-details-persister"
        ]
      },
      {
        Effect   = "Allow",
        Action   = "s3:PutObject",
        Resource = format("%s/*", module.generated_jwt_details_bucket.s3_bucket_arn)
      }
    ]
  })
}

resource "aws_iam_policy" "be_client_purpose_updater" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeClientPurposeUpdaterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_purpose.events",
          "${local.msk_group_iam_prefix}/*client-purpose-updater"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_delegation_outbound_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeDelegationOutboundWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_delegation.events",
          "${local.msk_group_iam_prefix}/*delegation-outbound-writer"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/outbound.*_delegation.events",
          "${local.msk_group_iam_prefix}/*delegation-outbound-writer"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_token_generation_readmodel_checker" {
  count = local.deploy_auth_server_refactor ? 1 : 0

  name = format("%sBeRefactorTokenGenerationReadmodelCheckerEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBAuthServerTables"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.platform_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.platform_states[0].arn),
          aws_dynamodb_table.token_generation_states[0].arn,
          format("%s/index/*", aws_dynamodb_table.token_generation_states[0].arn),
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_ipa_certified_attributes_importer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeIPACertifiedAttributesImporterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_eservice_template_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeEserviceTemplateProcessEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_eservice_template_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeEserviceTemplateReadModelWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_eservice_template.events",
          "${local.msk_group_iam_prefix}/*eservice-template-readmodel-writer",
          "${local.msk_group_iam_prefix}/*eservice-template-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_eservice_template_instances_updater" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeEserviceTemplateInstancesUpdaterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_eservice_template.events",
          "${local.msk_group_iam_prefix}/*eservice-template-instances-updater"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)
      }
    ]
  })
}

resource "aws_iam_policy" "be_refactor_eservice_template_outbound_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeEserviceTemplateOutboundWriterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_eservice_template.events",
          "${local.msk_group_iam_prefix}/*eservice-template-outbound-writer"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/outbound.*_eservice_template.events",
          "${local.msk_group_iam_prefix}/*eservice-template-outbound-writer"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_notification_email_sender" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeNotificationEmailSenderEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_topic_iam_prefix}/event-store.*_catalog.events",
          "${local.msk_topic_iam_prefix}/event-store.*_purpose.events",
          "${local.msk_group_iam_prefix}/*notification-email-sender"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_certified_email_sender" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeCertifiedEmailSenderEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_group_iam_prefix}/*certified-email-sender"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_selfcare_client_users_updater" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("%sBeSelfcareClientUsersUpdaterEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_documents_generator" {
  name = format("%sBeDocumentsGeneratorEs1", local.project_titled)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteS3ObjectsToBeSigned"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          format("%s/*", module.application_documents_bucket.s3_bucket_arn)
        ]
      },
      {
        Sid    = "ReadWriteDocumentsEvents"
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData",
          "kafka-cluster:WriteData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_agreement.events",
          "${local.msk_topic_iam_prefix}/event-store.*_purpose.events",
          "${local.msk_topic_iam_prefix}/event-store.*_purpose_template.events",
          "${local.msk_topic_iam_prefix}/event-store.*_delegation.events",
          "${local.msk_group_iam_prefix}/*documents_generator",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_purpose_template_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = "InteropBePurposeTemplateProcessPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)
      },
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_purpose_template_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = "InteropBePurposeTemplateReadModelWriterEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_purpose_template.events",
          "${local.msk_group_iam_prefix}/*purpose-template-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_notification_config_process" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = "InteropBeNotificationConfigProcessPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_notification_config_readmodel_writer" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = "InteropBeNotificationConfigReadModelWriterEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:AlterGroup",
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeGroup",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:ReadData"
        ]

        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/event-store.*_notification_config.events",
          "${local.msk_group_iam_prefix}/*notification-config-readmodel-writer-sql"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "be_in_app_notification_manager" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = "InteropBeInAppNotificationManagerPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic",
          "kafka-cluster:WriteData"
        ]
        Resource = [
          aws_msk_cluster.platform_events[0].arn,
          "${local.msk_topic_iam_prefix}/*_application.audit",
        ]
      }
    ]
  })
}
