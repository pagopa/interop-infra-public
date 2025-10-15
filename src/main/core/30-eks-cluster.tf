data "aws_subnets" "eks_control_plane" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = toset(local.eks_control_plane_cidrs)
  }
}

data "aws_subnets" "eks_workload" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = toset(local.eks_workload_cidrs)
  }
}

data "aws_subnets" "public_catalog_eks_workload" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = toset(local.public_catalog_eks_workload_cidrs)
  }
}

locals {
  system_namespaces         = ["kube-system"]
  application_namespaces    = ["${var.env}*"]
  observability_namespaces  = ["aws-observability"]
  tools_namespaces          = local.deploy_keda ? ["keda"] : []
  public_catalog_namespaces = ["${var.env}-public-catalog"]
}

resource "aws_iam_policy" "fargate_profile_logging" {
  name = "EksFargateProfileLoggingEs1"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:putRetentionPolicy",
          "logs:DeleteRetentionPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.11.1"

  cluster_name    = format("%s-eks-cluster-%s", var.short_name, var.env)
  cluster_version = var.eks_k8s_version

  vpc_id                   = module.vpc.vpc_id
  control_plane_subnet_ids = data.aws_subnets.eks_control_plane.ids
  cluster_ip_family        = "ipv4"
  # CIDR range for K8s services IPs. Just to avoid potential overlap with other networks
  cluster_service_ipv4_cidr = "10.1.0.0/21"

  node_security_group_enable_recommended_rules = false

  cluster_security_group_additional_rules = {
    from_github_runners = {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.github_runners.id
    }

    from_vpn_clients = {
      type                     = "ingress"
      from_port                = 0
      to_port                  = 65535
      protocol                 = "tcp"
      source_security_group_id = aws_security_group.vpn_clients.id
    }
  }

  cluster_endpoint_public_access  = var.env == "dev" ? true : false
  cluster_endpoint_private_access = true

  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = false

  cluster_security_group_use_name_prefix = false
  cluster_security_group_name            = format("eks/cp-eni/%s-eks-cluster-%s", local.project, var.env)

  iam_role_use_name_prefix = false
  iam_role_name            = format("%s-eks-cluster-%s-es1", local.project, var.env)

  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = var.env == "prod" ? 365 : 90

  kms_key_enable_default_policy = true
  kms_key_administrators = [
    data.aws_iam_role.github_iac.arn,
    data.aws_iam_role.sso_admin.arn
  ]

  cluster_addons = {
    vpc-cni = {
      addon_version               = var.eks_vpc_cni_version
      most_recent                 = false # use 'default' version for the K8s version
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "NONE"
    }

    coredns = {
      addon_version               = var.eks_coredns_version
      most_recent                 = false # use 'default' version for the K8s version
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "NONE"
    }

    kube-proxy = {
      addon_version               = var.eks_kube_proxy_version
      most_recent                 = false # use 'default' version for the K8s version
      resolve_conflicts_on_create = "NONE"
      resolve_conflicts_on_update = "NONE"
    }
  }

  fargate_profile_defaults = {
    subnet_ids               = data.aws_subnets.eks_workload.ids
    iam_role_use_name_prefix = false

    iam_role_additional_policies = {
      fargate_logging = aws_iam_policy.fargate_profile_logging.arn
    }
  }

  fargate_profiles = merge(
    {
      system = {
        name      = "Interop-EKS-SystemProfile-Es1"
        selectors = [for ns in local.system_namespaces : { namespace = ns }]
      }

      application = {
        name      = "Interop-EKS-ApplicationProfile-Es1"
        selectors = [for ns in local.application_namespaces : { namespace = ns }]
      }

      observability = {
        name      = "Interop-EKS-ObservabilityProfile-Es1"
        selectors = [for ns in local.observability_namespaces : { namespace = ns }]
      },

      public_catalog = {
        name       = "100-Interop-EKS-PublicCatalogProfile-Es1" # in case of multiple profiles match for a pod, Fargate uses alphanumeric order to choose the profile
        selectors  = [for ns in local.public_catalog_namespaces : { namespace = ns }]
        subnet_ids = data.aws_subnets.public_catalog_eks_workload.ids
      },
    },
    length(local.tools_namespaces) > 0 ? ({
      tools = {
        name      = "Interop-EKS-ToolsProfile-Es1"
        selectors = [for ns in local.tools_namespaces : { namespace = ns }]
      }
    }) : {}
  )

  access_entries = merge(
    {
      sso_full_admin = {
        kubernetes_groups = []
        principal_arn     = data.aws_iam_role.sso_admin.arn
        policy_associations = {
          admin_policy = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              namespaces = []
              type       = "cluster"
            }
          }
        }
      }
    },
    {
      deployment_role = {
        principal_arn     = local.deployment_github_repo_iam_role_arn
        kubernetes_groups = []
        policy_associations = {
          namespace_edit = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
            access_scope = {
              type       = "namespace"
              namespaces = ["${var.env}"]
            }
          }
        }
      }
    },
    var.analytics_k8s_namespace != null ? {
      analytics_deployment_role = {
        principal_arn     = local.analytics_deployment_github_repo_iam_role_arn
        kubernetes_groups = []
        policy_associations = {
          namespace_edit = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
            access_scope = {
              type       = "namespace"
              namespaces = [var.analytics_k8s_namespace]
            }
          }
        }
      }
    } : {},
    var.public_catalog_k8s_namespace != null ? {
      public_catalog_deployment_role = {
        principal_arn     = local.public_catalog_deployment_github_repo_iam_role_arn
        kubernetes_groups = []
        policy_associations = {
          namespace_edit = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
            access_scope = {
              type       = "namespace"
              namespaces = [var.public_catalog_k8s_namespace]
            }
          }
        }
      }
    } : {}
  )
}


# applied to nodes
resource "aws_vpc_security_group_ingress_rule" "from_vpn_clients" {
  count = var.env == "dev" ? 1 : 0

  security_group_id = module.eks.cluster_primary_security_group_id

  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.vpn_clients.id
}
