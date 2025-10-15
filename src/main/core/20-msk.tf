data "aws_subnets" "msk" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = toset(local.msk_cidrs)
  }
}

resource "aws_security_group" "msk_platform_events" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  description = "MSK platform-events-${var.env}"
  name        = "msk/platform-events-${var.env}"

  vpc_id = module.vpc.vpc_id

  ingress {
    description = "IAM clients inside VPC"
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    security_groups = [
      module.eks.cluster_primary_security_group_id,
      aws_security_group.vpn_clients.id,
      aws_security_group.github_runners.id
    ]
  }
}

resource "aws_kms_key" "msk_platform_events" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  description              = format("msk/%s-platform-events-%s", var.short_name, var.env)
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

resource "aws_cloudwatch_log_group" "msk_platform_events" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  name = format("/aws/msk/%s-platform-events-%s/brokers", var.short_name, var.env)

  retention_in_days = var.env == "prod" ? 90 : 30
  skip_destroy      = true
}

resource "aws_msk_configuration" "custom" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  kafka_versions = [var.msk_version]
  name           = format("%s-platform-events-custom-config-%s", local.project, var.env)

  server_properties = <<-EOT
    # 10y offsets retention
    offsets.retention.minutes=5256000
  EOT
}


resource "aws_msk_cluster" "platform_events" {
  count = local.deploy_be_refactor_infra ? 1 : 0

  cluster_name           = format("%s-platform-events-%s", var.short_name, var.env)
  kafka_version          = var.msk_version
  number_of_broker_nodes = var.msk_number_brokers

  client_authentication {
    sasl {
      iam = true
    }
  }

  broker_node_group_info {
    instance_type = var.msk_brokers_instance_class

    client_subnets  = slice(data.aws_subnets.msk[0].ids, 0, var.msk_number_azs)
    security_groups = [aws_security_group.msk_platform_events[0].id]

    storage_info {
      ebs_storage_info {
        volume_size = var.msk_brokers_storage_gib
      }
    }

    connectivity_info {
      vpc_connectivity {
        client_authentication {
          sasl {
            iam = true
          }
        }
      }
    }
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk_platform_events[0].arn
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_platform_events[0].name
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.custom[0].arn
    revision = aws_msk_configuration.custom[0].latest_revision
  }
}

locals {
  attach_msk_cross_account_cluster_policy = length(compact([
    var.msk_signalhub_account_id,
    var.msk_tracing_account_id
  ])) > 0
}

data "aws_iam_policy_document" "msk_cross_account" {
  count = local.deploy_be_refactor_infra && local.attach_msk_cross_account_cluster_policy ? 1 : 0

  statement {
    sid = "CrossAccountConnection"

    principals {
      type        = "AWS"
      identifiers = compact([var.msk_signalhub_account_id, var.msk_tracing_account_id, var.msk_probing_account_id])
    }

    actions = [
      "kafka:CreateVpcConnection",
      "kafka:DescribeCluster",
      "kafka:DescribeClusterV2",
      "kafka:GetBootstrapBrokers",
    ]
    resources = [aws_msk_cluster.platform_events[0].arn]
  }

  dynamic "statement" {
    for_each = compact([var.msk_signalhub_account_id])

    content {
      sid = "SignalHubOutboundTopicsAccess"

      principals {
        type        = "AWS"
        identifiers = [var.msk_signalhub_account_id]
      }

      actions = [
        "kafka-cluster:AlterGroup",
        "kafka-cluster:Connect",
        "kafka-cluster:DescribeGroup",
        "kafka-cluster:DescribeTopic",
        "kafka-cluster:ReadData"
      ]
      resources = [
        aws_msk_cluster.platform_events[0].arn,
        "${local.msk_topic_iam_prefix}/outbound.*.events",
        "${local.msk_group_iam_prefix}/signalhub-*"
      ]
    }
  }

  dynamic "statement" {
    for_each = compact([var.msk_tracing_account_id])

    content {
      sid = "TracingOutboundTopicsAccess"

      principals {
        type        = "AWS"
        identifiers = [var.msk_tracing_account_id]
      }

      actions = [
        "kafka-cluster:AlterGroup",
        "kafka-cluster:Connect",
        "kafka-cluster:DescribeGroup",
        "kafka-cluster:DescribeTopic",
        "kafka-cluster:ReadData"
      ]
      resources = [
        aws_msk_cluster.platform_events[0].arn,
        "${local.msk_topic_iam_prefix}/outbound.*.events",
        "${local.msk_group_iam_prefix}/tracing-*"
      ]
    }
  }

  dynamic "statement" {
    for_each = compact([var.msk_probing_account_id])

    content {
      sid = "ProbingOutboundTopicsAccess"

      principals {
        type        = "AWS"
        identifiers = [var.msk_probing_account_id]
      }

      actions = [
        "kafka-cluster:AlterGroup",
        "kafka-cluster:Connect",
        "kafka-cluster:DescribeGroup",
        "kafka-cluster:DescribeTopic",
        "kafka-cluster:ReadData"
      ]
      resources = [
        aws_msk_cluster.platform_events[0].arn,
        "${local.msk_topic_iam_prefix}/outbound.*.events",
        "${local.msk_group_iam_prefix}/probing-*"
      ]
    }
  }
}

resource "aws_msk_cluster_policy" "cross_account" {
  count = local.deploy_be_refactor_infra && local.attach_msk_cross_account_cluster_policy ? 1 : 0

  cluster_arn = aws_msk_cluster.platform_events[0].arn

  policy = data.aws_iam_policy_document.msk_cross_account[0].json
}
