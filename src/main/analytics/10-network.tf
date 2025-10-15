data "aws_vpc_endpoint" "s3" {
  vpc_id       = data.aws_vpc.core.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

data "aws_prefix_list" "s3" {
  prefix_list_id = data.aws_vpc_endpoint.s3.prefix_list_id
}

resource "aws_security_group" "analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name        = format("redshift/%s-analytics-%s", local.project, var.env)
  description = "SG for interop-analytics-${var.env} Redshift cluster"
  vpc_id      = data.aws_vpc.core.id

  ingress {
    from_port       = 5432
    to_port         = 5439
    protocol        = "tcp"
    security_groups = [data.aws_security_group.vpn_clients.id]
  }

  ingress {
    from_port       = 5432
    to_port         = 5439
    protocol        = "tcp"
    security_groups = [data.aws_security_group.core_eks_cluster_node.id]
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  # Ingress rule required by QuickSight (see https://docs.aws.amazon.com/quicksight/latest/user/vpc-security-groups.html)
  ingress {
    from_port       = 5432
    to_port         = 5439
    protocol        = "tcp"
    security_groups = [aws_security_group.quicksight_analytics[0].id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "quicksight_analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name        = format("quicksight/%s-analytics-%s", local.project, var.env)
  description = "SG for interop-analytics-${var.env} QuickSight access to RedShift cluster"
  vpc_id      = data.aws_vpc.core.id
}

resource "aws_vpc_security_group_egress_rule" "quicksight_analytics_to_redshift" {
  count = local.deploy_redshift_cluster ? 1 : 0

  security_group_id = aws_security_group.quicksight_analytics[0].id
  description       = "Egress tcp rule from QuickSight to RedShift cluster"

  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5439
  referenced_security_group_id = aws_security_group.analytics[0].id
}


resource "aws_redshift_subnet_group" "analytics" {
  count = local.deploy_redshift_cluster ? 1 : 0

  name       = format("%s-analytics-%s", local.project, var.env)
  subnet_ids = data.aws_subnets.analytics.ids
}

locals {
  deploy_tracing_redshift_vpce_authorization        = (var.tracing_aws_account_id != null && var.tracing_vpc_id != null) ? true : false
  deploy_redshift_vpce_authorization_from_qa_to_dev = (var.analytics_qa_account_id != null && var.analytics_qa_vpc_id != null) ? true : false
}

resource "aws_redshift_endpoint_authorization" "analytics_tracing" {
  count = local.deploy_redshift_cluster && local.deploy_tracing_redshift_vpce_authorization ? 1 : 0

  account            = var.tracing_aws_account_id
  cluster_identifier = aws_redshift_cluster.analytics[0].cluster_identifier
  vpc_ids            = [var.tracing_vpc_id]
}

resource "aws_redshift_endpoint_authorization" "analytics_from_qa_to_dev" {
  count = local.deploy_redshift_cluster && local.deploy_redshift_vpce_authorization_from_qa_to_dev ? 1 : 0

  account            = var.analytics_qa_account_id
  cluster_identifier = aws_redshift_cluster.analytics[0].cluster_identifier
  vpc_ids            = [var.analytics_qa_vpc_id]
}
