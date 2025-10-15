module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("eks-cluster-autoscaler-%s-es1", var.env)

  oidc_providers = {
    cluster = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [module.eks.cluster_name]
}

module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = format("aws-load-balancer-controller-%s-es1", var.env)

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  role_description = "Role for AWS Load Balancer Controller"

  role_policy_arns = {
    aws_lb = aws_iam_policy.aws_load_balancer_controller.arn
  }
}

# module "aws_load_balancer_controller_irsa_v2" {
#   count  = var.env == "dev" ? 1 : 0
#   source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#
#   role_name = format("aws-load-balancer-controller-v2-%s-es1", var.env)
#
#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
#     }
#   }
#
#   role_description = "Role v2 for AWS Load Balancer Controller"
#
#   attach_load_balancer_controller_targetgroup_binding_only_policy = true
# }

module "adot_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.11.1"

  role_name = format("adot-collector-%s-es1", var.env)

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["aws-observability:adot-collector"]
    }
  }

  role_policy_arns = {
    cloudwatch = data.aws_iam_policy.cloudwatch_agent_server.arn
  }
}
