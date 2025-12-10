###############################################################################################################################################################
#####        █████╗ ██╗      ██████╗  ██████╗ ██╗  ██╗██╗██╗   ██╗███████╗     ██╗  ██╗     ██████╗ ██╗      █████╗ ███╗   ██╗██╗  ██╗                    #####
#####       ██╔══██╗██║     ██╔════╝ ██╔═══██╗██║  ██║██║██║   ██║██╔════╝     ╚██╗██╔╝     ██╔══██╗██║     ██╔══██╗████╗  ██║██║ ██╔╝                    #####
#####       ███████║██║     ██║  ███╗██║   ██║███████║██║██║   ██║█████╗        ╚███╔╝      ██████╔╝██║     ███████║██╔██╗ ██║█████╔╝                     #####
#####       ██╔══██║██║     ██║   ██║██║   ██║██╔══██║██║╚██╗ ██╔╝██╔══╝        ██╔██╗      ██╔═══╝ ██║     ██╔══██║██║╚██╗██║██╔═██╗                     #####
#####       ██║  ██║███████╗╚██████╔╝╚██████╔╝██║  ██║██║ ╚████╔╝ ███████╗     ██╔╝ ██╗     ██║     ███████╗██║  ██║██║ ╚████║██║  ██╗                    #####
#####       ╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝     ╚═╝  ╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝                    #####
###############################################################################################################################################################
# Authors: Tristan Truckle & PLANK Team
# Version: 1.0
# Date: 15-01-2026
# Subject: Terraform AWS Infrastructure Deployment Project for AlgoHive x Plank
# Description:
# Notes :
###############################################################################################################################################################

###############################################################################################################################################################
# NETWORK MODULES
###############################################################################################################################################################

module "vpc" {
  source       = "./aws/network/vpc"
  vpc_cidr     = var.vpc_cidr
  project_name = local.project
}

module "subnets" {
  source             = "./aws/network/subnets"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  project_name       = local.project
  tags               = local.tags
}


module "internet_gateway" {
  source       = "./aws/network/internet-gateway"
  vpc_id       = module.vpc.vpc_id
  project_name = local.project
}

module "nat_gateway" {
  source            = "./aws/network/nat-gateway"
  public_subnet_ids = module.subnets.public_subnet_ids
  project_name      = local.project
  nat_gateway_count = var.nat_gateway_count

  depends_on = [module.internet_gateway]
}

module "public_routes" {
  source             = "./aws/network/route-tables"
  vpc_id             = module.vpc.vpc_id
  igw_id             = module.internet_gateway.igw_id
  nat_gateway_ids    = module.nat_gateway.nat_gateway_ids
  project_name       = local.project
  public_subnet_ids  = module.subnets.public_subnet_ids
  private_subnet_ids = module.subnets.private_subnet_ids
}

# ###############################################################################################################################################################
# # IAM MODULES
# ###############################################################################################################################################################

module "eks_cluster_role" {
  source       = "./aws/iam/eks-cluster-role"
  project_name = local.project
}

module "eks_node_role" {
  source       = "./aws/iam/eks-node-role"
  project_name = local.project
}

# ###############################################################################################################################################################
# # EKS MODULES
# ###############################################################################################################################################################

module "eks_cluster" {
  source       = "./aws/eks/cluster"
  cluster_name = "${local.project}-${local.environment}"

  cluster_version         = var.eks_cluster_version
  cluster_role_arn        = module.eks_cluster_role.role_arn
  node_role_arn           = module.eks_node_role.role_arn
  subnet_ids              = module.subnets.private_subnet_ids
  endpoint_public_access  = var.eks_endpoint_public_access
  endpoint_private_access = var.eks_endpoint_private_access
  node_pools              = var.eks_node_pools

  endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs
  deletion_protection          = var.eks_deletion_protection
  enable_secrets_encryption    = var.eks_enable_secrets_encryption
  secrets_kms_key_arn          = var.eks_secrets_kms_key_arn
  tags                         = local.tags

  depends_on = [module.eks_cluster_role, module.eks_node_role]
}

module "eks_addons" {
  source = "./aws/eks/addons"

  cluster_name                          = module.eks_cluster.cluster_name
  enable_cloudwatch_observability_addon = var.enable_cloudwatch_observability_addon
}

module "eks_capabilities" {
  source = "./aws/eks/capabilities"

  cluster_name                     = module.eks_cluster.cluster_name
  project_name                     = local.project
  aws_region                       = var.aws_region
  tags                             = local.tags
  enable_argocd_capability         = var.enable_eks_argocd_capability
  argocd_capability_name           = var.eks_argocd_capability_name
  argocd_namespace                 = var.eks_argocd_namespace
  argocd_delete_propagation_policy = var.eks_argocd_delete_propagation_policy
  argocd_idc_instance_arn          = var.eks_argocd_idc_instance_arn
  argocd_idc_region                = var.eks_argocd_idc_region
  argocd_vpce_ids                  = var.eks_argocd_vpce_ids
  argocd_rbac_role_mappings        = var.eks_argocd_rbac_role_mappings

  depends_on = [module.eks_cluster, module.eks_addons]
}

module "aws_auth" {
  source         = "./aws/eks/aws-auth"
  cluster_name   = module.eks_cluster.cluster_name
  access_entries = var.eks_access_entries
}

# ###############################################################################################################################################################
# # OBSERVABILITY MODULES
# ###############################################################################################################################################################

module "cloudwatch" {
  source                       = "./aws/observability/cloudwatch"
  cluster_name                 = module.eks_cluster.cluster_name
  aws_region                   = var.aws_region
  dashboard_name               = "${local.project}-${local.environment}-eks"
  alarm_actions                = var.cloudwatch_alarm_actions
  ok_actions                   = var.cloudwatch_ok_actions
  node_cpu_alarm_threshold     = var.cloudwatch_node_cpu_alarm_threshold
  node_memory_alarm_threshold  = var.cloudwatch_node_memory_alarm_threshold
  pending_pods_alarm_threshold = var.cloudwatch_pending_pods_alarm_threshold
  pod_restarts_alarm_threshold = var.cloudwatch_pod_restarts_alarm_threshold

  depends_on = [module.eks_addons]
}
