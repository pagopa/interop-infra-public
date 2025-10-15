resource "aws_redshift_subnet_group" "analytics_from_qa_to_dev" {
  count = local.deploy_redshift_cross_account ? 1 : 0

  name       = format("%s-%s", local.project, data.aws_redshift_cluster.cross_account[0].cluster_identifier)
  subnet_ids = data.aws_subnets.analytics.ids
}

resource "aws_security_group" "analytics_from_qa_to_dev" {
  count = local.deploy_redshift_cross_account ? 1 : 0

  name        = format("redshift/%s-analytics-from-%s-to-%s", local.project, var.env, var.redshift_cross_account_cluster.aws_account_env)
  description = format("SG for the Analytics Redshift-managed VPC endpoint from %s to %s", var.env, var.redshift_cross_account_cluster.aws_account_env)
  vpc_id      = data.aws_vpc.core.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [data.aws_security_group.vpn_clients.id]
    description     = "From VPN clients"
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [data.aws_security_group.core_eks_cluster_node.id]
    description     = "From EKS pods"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_redshift_endpoint_access" "analytics_from_qa_to_dev" {
  count = local.deploy_redshift_cross_account ? 1 : 0

  endpoint_name          = format("%s-%s", local.project, data.aws_redshift_cluster.cross_account[0].cluster_identifier)
  resource_owner         = var.redshift_cross_account_cluster.aws_account_id
  cluster_identifier     = data.aws_redshift_cluster.cross_account[0].cluster_identifier
  subnet_group_name      = aws_redshift_subnet_group.analytics_from_qa_to_dev[0].name
  vpc_security_group_ids = [aws_security_group.analytics_from_qa_to_dev[0].id]
}