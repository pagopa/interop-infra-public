locals {
  eks_workload_cidrs         = ["10.0.0.0/21", "10.0.8.0/21", "10.0.16.0/21"]
  eks_control_plane_cidrs    = ["10.0.24.0/24", "10.0.25.0/24", "10.0.26.0/24"]
  aurora_platform_data_cidrs = ["10.0.27.0/24", "10.0.28.0/24", "10.0.29.0/24"]
  docdb_read_model_cidrs     = ["10.0.30.0/24", "10.0.31.0/24", "10.0.32.0/24"]
  vpce_cidrs                 = ["10.0.33.0/24", "10.0.34.0/24", "10.0.35.0/24"]
  msk_cidrs                  = ["10.0.36.0/24", "10.0.37.0/24", "10.0.38.0/24"]
  vpn_cidrs                  = ["10.0.39.0/24", "10.0.40.0/24", "10.0.41.0/24"]
  egress_cidrs               = ["10.0.42.0/24", "10.0.43.0/24", "10.0.44.0/24"]
  bastion_host_cidrs         = ["10.0.45.0/24"]
  int_lbs_cidrs              = ["10.0.46.0/24", "10.0.47.0/24", "10.0.48.0/24"]
  analytics_cidrs            = ["10.0.49.0/24", "10.0.50.0/24", "10.0.51.0/24"]

  public_catalog_int_lbs_cidrs      = ["10.0.52.0/27", "10.0.52.32/27", "10.0.52.64/27"]
  public_catalog_aurora_cidrs       = ["10.0.52.96/27", "10.0.52.128/27", "10.0.52.160/27"]
  public_catalog_eks_workload_cidrs = ["10.0.53.0/24", "10.0.54.0/24", "10.0.55.0/24"]

  eks_workload_subnets_names = [for idx, subn in local.eks_workload_cidrs :
  format("%s-eks-workload-%d-%s", var.short_name, idx + 1, var.env)]

  eks_control_plane_subnets_names = [for idx, subn in local.eks_control_plane_cidrs :
  format("%s-eks-cp-%d-%s", var.short_name, idx + 1, var.env)]

  aurora_platform_data_subnets_names = [for idx, subn in local.aurora_platform_data_cidrs :
  format("%s-aurora-platform-data-%d-%s", var.short_name, idx + 1, var.env)]

  docdb_read_model_subnets_names = [for idx, subn in local.docdb_read_model_cidrs :
  format("%s-docdb-read-model-%d-%s", var.short_name, idx + 1, var.env)]

  vpce_subnets_names = [for idx, subn in local.vpce_cidrs :
  format("%s-vpce-%d-%s", var.short_name, idx + 1, var.env)]

  msk_subnets_names = [for idx, subn in local.msk_cidrs :
  format("%s-msk-events-%d-%s", var.short_name, idx + 1, var.env)]

  vpn_subnets_names = [for idx, subn in local.vpn_cidrs :
  format("%s-vpn-%d-%s", var.short_name, idx + 1, var.env)]

  egress_subnets_names = [for idx, subn in local.egress_cidrs :
  format("%s-egress-%d-%s", var.short_name, idx + 1, var.env)]

  bastion_host_subnets_names = [for idx, subn in local.bastion_host_cidrs :
  format("%s-bastion-host-%d-%s", var.short_name, idx + 1, var.env)]

  int_lbs_subnets_names = [for idx, subn in local.int_lbs_cidrs :
  format("%s-int-lbs-%d-%s", var.short_name, idx + 1, var.env)]

  analytics_subnets_names = [for idx, subn in local.analytics_cidrs :
  format("%s-analytics-%d-%s", var.short_name, idx + 1, var.env)]

  public_catalog_int_lbs_subnets_names = [for idx, subn in local.public_catalog_int_lbs_cidrs :
  format("%s-public-catalog-int-lbs-%d-%s", var.short_name, idx + 1, var.env)]

  public_catalog_aurora_subnets_names = [for idx, subn in local.public_catalog_aurora_cidrs :
  format("%s-public-catalog-aurora-%d-%s", var.short_name, idx + 1, var.env)]

  public_catalog_eks_workload_subnets_names = [for idx, subn in local.public_catalog_eks_workload_cidrs :
  format("%s-public-catalog-eks-workload-%d-%s", var.short_name, idx + 1, var.env)]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = format("%s-vpc-%s", var.short_name, var.env)
  cidr = "10.0.0.0/16"
  azs  = var.azs

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_igw              = true
  map_public_ip_on_launch = false
  enable_nat_gateway      = true
  # This will create N instances of NAT (N = #AZs) in the first N public subnets specified in 'public_subnets'
  one_nat_gateway_per_az = true

  # Order matters: the first N subnets (N = #AZs) will host a NAT instance. See 'one_nat_gateway_per_az'
  public_subnets      = concat(local.egress_cidrs, local.bastion_host_cidrs)
  public_subnet_names = concat(local.egress_subnets_names, local.bastion_host_subnets_names)

  # TODO: some of these subnets should be in the 'intra' class, but we need to move the TF address without destroying the subnets
  private_subnets      = concat(local.eks_workload_cidrs, local.public_catalog_eks_workload_cidrs)
  private_subnet_names = concat(local.eks_workload_subnets_names, local.public_catalog_eks_workload_subnets_names)

  # TODO: MSK subnets should be in the 'intra' class, but we need to move the TF address without destroying the subnets
  database_subnets                   = concat(local.aurora_platform_data_cidrs, local.docdb_read_model_cidrs, local.analytics_cidrs, local.public_catalog_aurora_cidrs)
  database_subnet_names              = concat(local.aurora_platform_data_subnets_names, local.docdb_read_model_subnets_names, local.analytics_subnets_names, local.public_catalog_aurora_subnets_names)
  create_database_subnet_group       = false
  create_database_subnet_route_table = true
  create_database_nat_gateway_route  = false

  intra_subnets      = concat(local.eks_control_plane_cidrs, local.vpce_cidrs, local.vpn_cidrs, local.msk_cidrs, local.int_lbs_cidrs, local.public_catalog_int_lbs_cidrs)
  intra_subnet_names = concat(local.eks_control_plane_subnets_names, local.vpce_subnets_names, local.vpn_subnets_names, local.msk_subnets_names, local.int_lbs_subnets_names, local.public_catalog_int_lbs_subnets_names)
}

data "aws_subnets" "int_lbs" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }

  filter {
    name   = "cidr-block"
    values = toset(local.int_lbs_cidrs)
  }
}

resource "aws_ec2_tag" "int_lbs" {
  for_each = toset(data.aws_subnets.int_lbs.ids)

  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
