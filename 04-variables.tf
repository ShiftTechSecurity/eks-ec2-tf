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
# VARIABLES - Global Inputs
###############################################################################################################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "availability_zones" {
  description = "List of availability zones for the subnets"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
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

variable "domain_name" {
  description = "Base domain for ACM and ALB"
  type        = string
  default     = "plank.fr"
}

variable "eks_cluster_version" {
  description = "Kubernetes version for EKS (null = AWS default/latest supported)"
  type        = string
  default     = null
}

variable "eks_endpoint_public_access" {
  description = "Expose EKS API endpoint publicly"
  type        = bool
  default     = false
}

variable "eks_endpoint_private_access" {
  description = "Expose EKS API endpoint privately"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access_cidrs" {
  description = "Allowed CIDRs for public EKS API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_node_pools" {
  description = "Built-in EKS Auto Mode node pools"
  type        = list(string)
  default     = ["system", "general-purpose"]
}

variable "eks_enabled_cluster_log_types" {
  description = "Enabled EKS control plane logs"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_cloudwatch_observability_addon" {
  description = "Enable the EKS amazon-cloudwatch-observability managed add-on"
  type        = bool
  default     = true
}

variable "enable_eks_argocd_capability" {
  description = "Enable EKS managed Argo CD capability"
  type        = bool
  default     = false
}

variable "eks_argocd_capability_name" {
  description = "Name of the EKS managed Argo CD capability"
  type        = string
  default     = "argocd-main"
}

variable "eks_argocd_namespace" {
  description = "Namespace where managed Argo CD is deployed"
  type        = string
  default     = "argocd"
}

variable "eks_argocd_delete_propagation_policy" {
  description = "Delete propagation policy for capability removal"
  type        = string
  default     = "RETAIN"

  validation {
    condition     = var.eks_argocd_delete_propagation_policy == "RETAIN"
    error_message = "eks_argocd_delete_propagation_policy currently only supports RETAIN."
  }
}

variable "eks_argocd_idc_instance_arn" {
  description = "AWS Identity Center instance ARN for Argo CD managed capability"
  type        = string
  default     = null
}

variable "eks_argocd_idc_region" {
  description = "AWS Identity Center region for Argo CD managed capability (null to use aws_region)"
  type        = string
  default     = null
}

variable "eks_argocd_vpce_ids" {
  description = "Optional VPC endpoint IDs allowed for Argo CD capability network access"
  type        = list(string)
  default     = []
}

variable "eks_argocd_rbac_role_mappings" {
  description = "Role mappings for Argo CD managed capability (AWS Identity Center identities)"
  type = set(object({
    role          = string
    identity_type = string
    identity_id   = string
  }))
  default = []
}

variable "eks_deletion_protection" {
  description = "Enable deletion protection for EKS cluster"
  type        = bool
  default     = false
}

variable "eks_enable_secrets_encryption" {
  description = "Enable KMS encryption for Kubernetes secrets"
  type        = bool
  default     = true
}

variable "eks_secrets_kms_key_arn" {
  description = "Optional existing KMS key ARN for EKS secrets encryption"
  type        = string
  default     = null
}

variable "eks_access_entries" {
  description = "Map of IAM principals and EKS access policies"
  type = map(object({
    principal_arn = string
    policy_arn    = string
  }))
  default = {}
}

variable "cloudwatch_alarm_actions" {
  description = "Alarm action ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}

variable "cloudwatch_ok_actions" {
  description = "OK action ARNs for CloudWatch alarms"
  type        = list(string)
  default     = []
}

variable "cloudwatch_node_cpu_alarm_threshold" {
  description = "Node CPU utilization alarm threshold (%)"
  type        = number
  default     = 85
}

variable "cloudwatch_node_memory_alarm_threshold" {
  description = "Node memory utilization alarm threshold (%)"
  type        = number
  default     = 85
}

variable "cloudwatch_pending_pods_alarm_threshold" {
  description = "Pending pods alarm threshold"
  type        = number
  default     = 10
}

variable "cloudwatch_pod_restarts_alarm_threshold" {
  description = "Pod restart count alarm threshold per period"
  type        = number
  default     = 20
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways to create"
  type        = number
  default     = 1
}
