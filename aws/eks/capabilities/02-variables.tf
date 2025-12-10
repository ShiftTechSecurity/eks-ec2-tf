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

variable "project_name" {
  description = "Project name used in IAM role naming"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags applied to capability resources"
  type        = map(string)
  default     = {}
}

variable "enable_argocd_capability" {
  description = "Enable EKS managed Argo CD capability"
  type        = bool
  default     = false
}

variable "argocd_capability_name" {
  description = "Capability name for managed Argo CD"
  type        = string
  default     = "argocd-main"
}

variable "argocd_namespace" {
  description = "Kubernetes namespace for managed Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_delete_propagation_policy" {
  description = "Delete propagation policy for capability removal"
  type        = string
  default     = "RETAIN"

  validation {
    condition     = var.argocd_delete_propagation_policy == "RETAIN"
    error_message = "argocd_delete_propagation_policy currently only supports RETAIN."
  }
}

variable "argocd_idc_instance_arn" {
  description = "AWS Identity Center instance ARN"
  type        = string
  default     = null

  validation {
    condition     = !var.enable_argocd_capability || length(try(trimspace(var.argocd_idc_instance_arn), "")) > 0
    error_message = "argocd_idc_instance_arn must be set when enable_argocd_capability is true."
  }
}

variable "argocd_idc_region" {
  description = "AWS Identity Center region (defaults to aws_region when null)"
  type        = string
  default     = null
}

variable "argocd_vpce_ids" {
  description = "Optional VPC endpoint IDs allowed for Argo CD network access"
  type        = list(string)
  default     = []
}

variable "argocd_rbac_role_mappings" {
  description = "RBAC mapping between Argo CD role and AWS Identity Center identity"
  type = set(object({
    role          = string
    identity_type = string
    identity_id   = string
  }))
  default = []
}

variable "argocd_role_propagation_wait" {
  description = "Wait duration to allow IAM role trust policy propagation before creating capability"
  type        = string
  default     = "30s"
}
