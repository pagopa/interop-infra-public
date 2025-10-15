# TODO: refactor all BE policies

resource "aws_iam_policy" "be_agreement_management" {
  name = "InteropBeAgreementManagementPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = module.persistence_events_queue.queue_arn
    }]
  })
}

resource "aws_iam_policy" "be_authorization_management" {
  name = "InteropBeAuthorizationManagementPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = module.persistence_events_queue.queue_arn
    }]
  })
}

resource "aws_iam_policy" "be_agreement_process" {
  name = "InteropBeAgreementProcessPolicyEs1"

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
        Resource = module.certified_mail_queue.queue_arn
      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = module.archived_agreements_for_purposes_queue.queue_arn
      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = module.archived_agreements_for_eservices_queue.queue_arn
      }
    ]
  })
}

resource "aws_iam_policy" "be_catalog_management" {
  name = "InteropBeCatalogManagementPolicyEs1"

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
    }]
  })
}

resource "aws_iam_policy" "be_authorization_server" {
  name = "InteropBeAuthorizationServerPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = module.generated_jwt_queue.queue_arn
      },
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
      },
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = format("%s/*", module.generated_jwt_details_fallback_bucket.s3_bucket_arn)
    }]
  })
}

resource "aws_iam_policy" "be_catalog_process" {
  name = "InteropBeCatalogProcessPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)
    }]
  })
}

resource "aws_iam_policy" "be_purpose_management" {
  name = "InteropBePurposeManagementPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sqs:SendMessage"
      Resource = module.persistence_events_queue.queue_arn
    }]
  })
}

resource "aws_iam_policy" "be_notifier" {
  name = "InteropBeNotifierPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ]
      Resource = module.persistence_events_queue.queue_arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGet*",
          "dynamodb:DescribeStream",
          "dynamodb:DescribeTable",
          "dynamodb:Get*",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWrite*",
          "dynamodb:CreateTable",
          "dynamodb:Delete*",
          "dynamodb:Update*",
          "dynamodb:PutItem"
        ]
        Resource = [
          aws_dynamodb_table.notification_events.arn,
          aws_dynamodb_table.notification_resources.arn,
        ]
      },
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
    }]
  })
}

resource "aws_iam_policy" "be_purpose_process" {
  name = "InteropBePurposeProcessPolicyEs1"

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
    }]
  })
}

resource "aws_iam_policy" "be_backend_for_frontend" {
  name = "InteropBeBackendForFrontendPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.application_documents_bucket.s3_bucket_arn,
          format("%s/*", module.application_documents_bucket.s3_bucket_arn),
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = format("%s/*", module.allow_list_bucket.s3_bucket_arn)
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
          "s3:ListBucket"
        ]
        Resource = [
          format("%s/*", module.privacy_notices_content_bucket.s3_bucket_arn),
          module.privacy_notices_content_bucket.s3_bucket_arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = compact([
          aws_dynamodb_table.privacy_notices.arn,
          # try(aws_dynamodb_table.be_refactor_privacy_notices[0].arn, "")
        ])
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
        ]
        Resource = aws_dynamodb_table.privacy_notices_acceptances.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.application_import_export_bucket.s3_bucket_arn,
          format("%s/*", module.application_import_export_bucket.s3_bucket_arn)
        ]
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

resource "aws_iam_policy" "be_selfcare_onboarding_consumer" {
  name = "InteropBeSelfcareOnboardingConsumerPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow",
      Action   = "kms:Sign",
      Resource = aws_kms_key.interop.arn
    }]
  })
}

resource "aws_iam_policy" "be_anac_certified_attributes_importer" {
  name = "InteropBeAnacCertifiedAttributesImporterPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow",
      Action   = "kms:Sign",
      Resource = aws_kms_key.interop.arn
    }]
  })
}

resource "aws_iam_policy" "be_ivass_certified_attributes_importer" {
  name = "InteropBeIvassCertifiedAttributesImporterPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "kms:Sign",
        Resource = aws_kms_key.interop.arn
      },
      {
        Effect   = "Allow",
        Action   = "s3:PutObject"
        Resource = format("%s/*", module.ivass_bucket.s3_bucket_arn)
      }
    ]
  })
}

resource "aws_iam_policy" "be_attributes_loader" {
  name = "InteropAttributesLoaderPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "kms:Sign"
      Resource = aws_kms_key.interop.arn
    }]
  })
}

resource "aws_iam_policy" "be_token_details_persister" {
  name = "InteropBeTokenDetailsPersisterPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = module.generated_jwt_queue.queue_arn
      },
      {
        Effect   = "Allow",
        Action   = "s3:PutObject",
        Resource = format("%s/*", module.generated_jwt_details_bucket.s3_bucket_arn)
    }]
  })
}

resource "aws_iam_policy" "be_tenants_certified_attributes_updater" {
  name = "InteropBeTenantsCertifiedAttributesUpdaterPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow",
      Action   = "kms:Sign",
      Resource = aws_kms_key.interop.arn
    }]
  })
}

resource "aws_iam_policy" "be_metrics_report_generator" {
  name = "InteropBeMetricsReportGeneratorPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ],
        Resource = module.athena_query_results_bucket.s3_bucket_arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = format("%s/*", module.athena_query_results_bucket.s3_bucket_arn)
      },
      {
        Effect = "Allow",
        Action = [
          "glue:GetDatabase",
          "glue:GetTable*"
        ],
        Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "be_pa_digitale_report_generator" {
  name = "InteropBePaDigitaleReportGeneratorPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:GetObject"
        Resource = format("%s/*", module.application_documents_bucket.s3_bucket_arn)
      },
      {
        Effect   = "Allow",
        Action   = "s3:PutObject"
        Resource = format("%s/*", module.platform_metrics_bucket.s3_bucket_arn)
    }]
  })
}

resource "aws_iam_policy" "be_dashboard_metrics_report_generator" {
  name = "InteropBeDashboardMetricsReportGeneratorPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:GetObject"
        Resource = format("%s/*", module.generated_jwt_details_bucket.s3_bucket_arn)
      },
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket"
        Resource = module.generated_jwt_details_bucket.s3_bucket_arn
      },
      {
        Effect   = "Allow",
        Action   = "s3:PutObject"
        Resource = format("%s/*", module.public_dashboards_bucket.s3_bucket_arn)
    }]
  })
}

resource "aws_iam_policy" "be_dtd_catalog_exporter" {
  name = "InteropBeDtdCatalogExporterPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:PutObject"
        Resource = format("%s/*", module.public_catalog_bucket.s3_bucket_arn)
      }
    ]
  })
}

resource "aws_iam_policy" "be_privacy_notices_updater" {
  name = "InteropBePrivacyNoticesUpdaterPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket"
        Resource = module.privacy_notices_history_bucket.s3_bucket_arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          format("%s/*", module.privacy_notices_history_bucket.s3_bucket_arn),
          format("%s/*", module.privacy_notices_content_bucket.s3_bucket_arn)
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.privacy_notices.arn
    }]
  })
}

resource "aws_iam_policy" "be_one_trust_notices" {
  name = "InteropBeOneTrustNoticesPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket"
        Resource = module.privacy_notices_history_bucket.s3_bucket_arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          format("%s/*", module.privacy_notices_history_bucket.s3_bucket_arn),
          format("%s/*", module.privacy_notices_content_bucket.s3_bucket_arn)
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.privacy_notices.arn,
    }]
  })
}

resource "aws_iam_policy" "be_purposes_archiver" {
  name = "InteropBePurposesArchiverPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = module.archived_agreements_for_purposes_queue.queue_arn,
    }]
  })
}

resource "aws_iam_policy" "be_eservice_descriptors_archiver" {
  name = "InteropBeEserviceDescriptorsArchiverPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = module.archived_agreements_for_eservices_queue.queue_arn,
      },
      {
        Effect   = "Allow"
        Action   = "kms:Sign"
        Resource = aws_kms_key.interop.arn
    }]
  })
}

resource "aws_iam_policy" "be_dtd_metrics" {
  name = "InteropBeDtdMetricsPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket"
        Resource = module.public_dashboards_bucket.s3_bucket_arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = format("%s/*", module.public_dashboards_bucket.s3_bucket_arn)
      },
      {
        Effect = "Allow",
        Action = [
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StartQueryExecution",
          "athena:StopQueryExecution"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          module.athena_query_results_bucket.s3_bucket_arn,
          format("%s/*", module.athena_query_results_bucket.s3_bucket_arn),
          module.generated_jwt_details_bucket.s3_bucket_arn,
          format("%s/*", module.generated_jwt_details_bucket.s3_bucket_arn)
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "glue:GetDatabase",
          "glue:GetTable*"
        ]
        Resource = "*"
      },
    ]
  })
}

data "aws_iam_policy" "cloudwatch_agent_server" {
  name = "CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name = "AWSLoadBalancerControllerIAMPolicyEs1"

  policy = <<-EOT
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "iam:CreateServiceLinkedRole"
                ],
                "Resource": "*",
                "Condition": {
                    "StringEquals": {
                        "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
                    }
                }
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeAccountAttributes",
                    "ec2:DescribeAddresses",
                    "ec2:DescribeAvailabilityZones",
                    "ec2:DescribeInternetGateways",
                    "ec2:DescribeVpcs",
                    "ec2:DescribeVpcPeeringConnections",
                    "ec2:DescribeSubnets",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeInstances",
                    "ec2:DescribeNetworkInterfaces",
                    "ec2:DescribeTags",
                    "ec2:GetCoipPoolUsage",
                    "ec2:DescribeCoipPools",
                    "elasticloadbalancing:DescribeLoadBalancers",
                    "elasticloadbalancing:DescribeLoadBalancerAttributes",
                    "elasticloadbalancing:DescribeListeners",
                    "elasticloadbalancing:DescribeListenerCertificates",
                    "elasticloadbalancing:DescribeSSLPolicies",
                    "elasticloadbalancing:DescribeRules",
                    "elasticloadbalancing:DescribeTargetGroups",
                    "elasticloadbalancing:DescribeTargetGroupAttributes",
                    "elasticloadbalancing:DescribeTargetHealth",
                    "elasticloadbalancing:DescribeTags"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "cognito-idp:DescribeUserPoolClient",
                    "acm:ListCertificates",
                    "acm:DescribeCertificate",
                    "iam:ListServerCertificates",
                    "iam:GetServerCertificate",
                    "waf-regional:GetWebACL",
                    "waf-regional:GetWebACLForResource",
                    "waf-regional:AssociateWebACL",
                    "waf-regional:DisassociateWebACL",
                    "wafv2:GetWebACL",
                    "wafv2:GetWebACLForResource",
                    "wafv2:AssociateWebACL",
                    "wafv2:DisassociateWebACL",
                    "shield:GetSubscriptionState",
                    "shield:DescribeProtection",
                    "shield:CreateProtection",
                    "shield:DeleteProtection"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:AuthorizeSecurityGroupIngress",
                    "ec2:RevokeSecurityGroupIngress"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateSecurityGroup"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateTags"
                ],
                "Resource": "arn:aws:ec2:*:*:security-group/*",
                "Condition": {
                    "StringEquals": {
                        "ec2:CreateAction": "CreateSecurityGroup"
                    },
                    "Null": {
                        "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                    }
                }
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateTags",
                    "ec2:DeleteTags"
                ],
                "Resource": "arn:aws:ec2:*:*:security-group/*",
                "Condition": {
                    "Null": {
                        "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                        "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                    }
                }
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ec2:AuthorizeSecurityGroupIngress",
                    "ec2:RevokeSecurityGroupIngress",
                    "ec2:DeleteSecurityGroup"
                ],
                "Resource": "*",
                "Condition": {
                    "Null": {
                        "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                    }
                }
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:CreateLoadBalancer",
                    "elasticloadbalancing:CreateTargetGroup"
                ],
                "Resource": "*",
                "Condition": {
                    "Null": {
                        "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                    }
                }
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:CreateListener",
                    "elasticloadbalancing:DeleteListener",
                    "elasticloadbalancing:CreateRule",
                    "elasticloadbalancing:DeleteRule"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:AddTags",
                    "elasticloadbalancing:RemoveTags"
                ],
                "Resource": [
                    "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                    "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                    "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
                ],
                "Condition": {
                    "Null": {
                        "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                        "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                    }
                }
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:AddTags",
                    "elasticloadbalancing:RemoveTags"
                ],
                "Resource": [
                    "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                    "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                    "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                    "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:AddTags"
                ],
                "Resource": [
                    "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                    "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                    "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
                ],
                "Condition": {
                    "StringEquals": {
                        "elasticloadbalancing:CreateAction": [
                            "CreateTargetGroup",
                            "CreateLoadBalancer"
                        ]
                    },
                    "Null": {
                        "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                    }
                }
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:ModifyLoadBalancerAttributes",
                    "elasticloadbalancing:SetIpAddressType",
                    "elasticloadbalancing:SetSecurityGroups",
                    "elasticloadbalancing:SetSubnets",
                    "elasticloadbalancing:DeleteLoadBalancer",
                    "elasticloadbalancing:ModifyTargetGroup",
                    "elasticloadbalancing:ModifyTargetGroupAttributes",
                    "elasticloadbalancing:DeleteTargetGroup"
                ],
                "Resource": "*",
                "Condition": {
                    "Null": {
                        "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                    }
                }
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:RegisterTargets",
                    "elasticloadbalancing:DeregisterTargets"
                ],
                "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "elasticloadbalancing:SetWebAcl",
                    "elasticloadbalancing:ModifyListener",
                    "elasticloadbalancing:AddListenerCertificates",
                    "elasticloadbalancing:RemoveListenerCertificates",
                    "elasticloadbalancing:ModifyRule"
                ],
                "Resource": "*"
            }
        ]
    }
  EOT
}

resource "aws_iam_policy" "be_datalake_data_export" {
  name = "InteropBeDatalakeDataExportPolicyEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = format("%s/*", module.data_lake_exports_bucket.s3_bucket_arn)
    }]
  })
}
