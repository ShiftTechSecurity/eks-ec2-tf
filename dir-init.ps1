# ==========================================
# Terraform AWS EKS on EC2 - Full Scaffold with Module Calls and Block Separators
# ==========================================

Write-Host "Creating Terraform EKS project structure with headers, module calls, and block separators..." -ForegroundColor Cyan

# -----------------------
# Fixed ASCII header
# -----------------------
$header = @'
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

'@

# -----------------------
# Root files
# -----------------------
$rootFiles = @(
    "00-providers.tf",
    "01-backend.tf",
    "02-versions.tf",
    "03-locals.tf",
    "04-variables.tf",
    "05-main.tf",
    "06-outputs.tf"
)

$otherRootFiles = @("terraform.tfvars","README.md")

# -----------------------
# Module folders (aligned with current repo structure)
# -----------------------
$folders = @(
    "aws/network/vpc",
    "aws/network/subnets",
    "aws/network/internet-gateway",
    "aws/network/nat-gateway",
    "aws/network/route-tables",

    "aws/iam/eks-cluster-role",
    "aws/iam/eks-node-role",

    "aws/eks/cluster",
    "aws/eks/addons",
    "aws/eks/capabilities",
    "aws/eks/aws-auth",

    "aws/observability/cloudwatch"
)

# -----------------------
# Module TF files
# -----------------------
$moduleFiles = @(
    "00-main.tf",
    "01-locals.tf",
    "02-variables.tf",
    "03-outputs.tf"
)

# -----------------------
# Create root files with header
# -----------------------
foreach ($file in $rootFiles) {
    if (-not (Test-Path $file)) {
        Set-Content -Path $file -Value $header -Encoding UTF8
    }
}

foreach ($file in $otherRootFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null
    }
}

# -----------------------
# Create folders and module files with header
# -----------------------
foreach ($folder in $folders) {

    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }

    foreach ($file in $moduleFiles) {
        $path = Join-Path $folder $file
        if (-not (Test-Path $path)) {
            Set-Content -Path $path -Value $header -Encoding UTF8
        }
    }
}

# -----------------------
# ROOT LOCALS.TF
# -----------------------
$localsContent = @'
###############################################################################################################################################################
# LOCALS - Global Terraform Context
###############################################################################################################################################################

locals {
  project     = "algohive-plank"
  environment = var.environment
  region      = var.aws_region
  azs         = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}
'@
Set-Content -Path "03-locals.tf" -Value ($header + "`n" + $localsContent) -Encoding UTF8

# -----------------------
# ROOT VARIABLES.TF
# -----------------------
$variablesContent = @'
###############################################################################################################################################################
# VARIABLES - Global Inputs
###############################################################################################################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "List of subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
}

variable "domain_name" {
  description = "Base domain for ACM and ALB"
  type        = string
  default     = "example.com"
}
'@
Set-Content -Path "04-variables.tf" -Value ($header + "`n" + $variablesContent) -Encoding UTF8

# -----------------------
# ROOT MAIN.TF - Module Calls (All Modules)
# -----------------------
$mainContent = @'
###############################################################################################################################################################
# MAIN - Module Composition
###############################################################################################################################################################

###############################################################################################################################################################
# NETWORK MODULES
###############################################################################################################################################################

module "vpc" {
  source = "./aws/network/vpc"
  cidr_block = var.vpc_cidr
  tags       = local.tags
}

module "subnets" {
  source = "./aws/network/subnets"
  vpc_id = module.vpc.vpc_id
  azs    = local.azs
  cidrs  = var.subnet_cidrs
  tags   = local.tags
}

module "internet_gateway" {
  source = "./aws/network/internet-gateway"
  vpc_id = module.vpc.vpc_id
  tags   = local.tags
}

module "nat_gateway" {
  source = "./aws/network/nat-gateway"
  public_subnet_ids = module.subnets.public_subnet_ids
  tags = local.tags
}

module "route_tables" {
  source = "./aws/network/route-tables"
  vpc_id = module.vpc.vpc_id
  igw_id = module.internet_gateway.igw_id
  nat_gateway_ids = module.nat_gateway.nat_gateway_ids
  public_subnet_ids = module.subnets.public_subnet_ids
  private_subnet_ids = module.subnets.private_subnet_ids
}

module "endpoints" {
  source = "./aws/network/endpoints"
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.subnets.private_subnet_ids
}

module "security_groups" {
  source = "./aws/network/security-groups"
  vpc_id = module.vpc.vpc_id
}

###############################################################################################################################################################
# IAM MODULES
###############################################################################################################################################################

module "eks_cluster_role" {
  source = "./aws/iam/eks-cluster-role"
}

module "eks_node_role" {
  source = "./aws/iam/eks-node-role"
}

module "oidc" {
  source = "./aws/iam/oidc"
  cluster_oidc_issuer = module.eks_cluster.oidc_issuer
}

module "iam_policies" {
  source = "./aws/iam/policies"
}

###############################################################################################################################################################
# EKS MODULES
###############################################################################################################################################################

module "eks_cluster" {
  source = "./aws/eks/cluster"
  cluster_name = "${local.project}-${local.environment}"
  subnet_ids   = module.subnets.private_subnet_ids
  role_arn     = module.eks_cluster_role.role_arn
  tags         = local.tags
}

module "eks_nodes" {
  source = "./aws/eks/node-groups"
  cluster_name    = module.eks_cluster.cluster_name
  cluster_version = module.eks_cluster.cluster_version
  subnet_ids      = module.subnets.private_subnet_ids
  node_role_arn   = module.eks_node_role.role_arn
  tags            = local.tags
}

module "eks_addons" {
  source = "./aws/eks/addons"
  cluster_name = module.eks_cluster.cluster_name
}

module "aws_auth" {
  source = "./aws/eks/aws-auth"
  cluster_name = module.eks_cluster.cluster_name
  node_role_arn = module.eks_node_role.role_arn
}

###############################################################################################################################################################
# COMPUTE MODULES
###############################################################################################################################################################

module "launch_templates" {
  source = "./aws/compute/launch-templates"
}

###############################################################################################################################################################
# LOAD BALANCING MODULES
###############################################################################################################################################################

module "acm" {
  source = "./aws/security/acm"
  domain_name = var.domain_name
}

module "alb" {
  source = "./aws/load-balancing/alb"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.subnets.public_subnet_ids
  certificate_arn = module.acm.certificate_arn
  tags            = local.tags
}

module "target_groups" {
  source = "./aws/load-balancing/target-groups"
  vpc_id = module.vpc.vpc_id
}

module "listeners" {
  source = "./aws/load-balancing/listeners"
  alb_arn = module.alb.alb_arn
  target_group_arns = module.target_groups.target_group_arns
}

###############################################################################################################################################################
# OBSERVABILITY MODULES
###############################################################################################################################################################

module "cloudwatch" {
  source = "./aws/observability/cloudwatch"
}

module "logs" {
  source = "./aws/observability/logs"
  cloudwatch_log_group_name = module.cloudwatch.log_group_name
}

###############################################################################################################################################################
# STORAGE MODULES
###############################################################################################################################################################

module "ebs" {
  source = "./aws/storage/ebs"
}

module "ecr" {
  source = "./aws/storage/ecr"
}

'@

Set-Content -Path "05-main.tf" -Value ($header + "`n" + $mainContent) -Encoding UTF8

# -----------------------
# ROOT OUTPUTS.TF
# -----------------------
$outputsContent = @'
###############################################################################################################################################################
# OUTPUTS - Expose Module Outputs
###############################################################################################################################################################

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "eks_cluster_name" {
  value = module.eks_cluster.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks_cluster.endpoint
}

output "eks_cluster_ca" {
  value = data.aws_eks_cluster.cluster.certificate_authority[0].data
}

output "alb_dns_name" {
  value = module.alb.dns_name
}
'@
Set-Content -Path "06-outputs.tf" -Value ($header + "`n" + $outputsContent) -Encoding UTF8

Write-Host "Terraform EKS project structure with headers, block separators, and full module calls created successfully." -ForegroundColor Green
