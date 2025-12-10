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

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = null
}

variable "cluster_role_arn" {
  description = "IAM role ARN used by EKS control plane"
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN used by EKS Auto Mode nodes"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs used by EKS"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Expose EKS API endpoint publicly"
  type        = bool
  default     = false
}

variable "endpoint_private_access" {
  description = "Expose EKS API endpoint privately in the VPC"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "Allowed CIDRs for the public EKS API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_pools" {
  description = "Built-in Auto Mode node pools"
  type        = list(string)
  default     = ["system", "general-purpose"]
}

variable "bootstrap_cluster_creator_admin_permissions" {
  description = "Grant cluster creator admin permissions at creation"
  type        = bool
  default     = true
}

variable "enabled_cluster_log_types" {
  description = "Control plane logs to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "deletion_protection" {
  description = "Enable deletion protection for the EKS cluster"
  type        = bool
  default     = false
}

variable "enable_secrets_encryption" {
  description = "Enable Kubernetes secrets encryption with KMS"
  type        = bool
  default     = true
}

variable "secrets_kms_key_arn" {
  description = "Existing KMS key ARN to use for EKS secrets encryption. If null, a key is created."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to EKS cluster"
  type        = map(string)
  default     = {}
}
