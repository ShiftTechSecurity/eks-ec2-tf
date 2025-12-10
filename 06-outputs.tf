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
# OUTPUTS - Expose Module Outputs
###############################################################################################################################################################

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.subnets.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.subnets.private_subnet_ids
}

output "internet_gateway_id" {
  value = module.internet_gateway.igw_id
}

output "public_route_table_id" {
  value = module.public_routes.public_route_table_id
}

output "nat_gateway_ids" {
  value = module.nat_gateway.nat_gateway_ids
}
output "private_route_table_ids" {
  value = module.public_routes.private_route_table_ids
}

output "eks_cluster_name" {
  value = module.eks_cluster.cluster_name
}

output "eks_cluster_arn" {
  value = module.eks_cluster.cluster_arn
}

output "eks_cluster_endpoint" {
  value = module.eks_cluster.endpoint
}

output "eks_cluster_version" {
  value = module.eks_cluster.cluster_version
}

output "eks_oidc_issuer" {
  value = module.eks_cluster.oidc_issuer
}

output "eks_cluster_role_arn" {
  value = module.eks_cluster_role.role_arn
}

output "eks_node_role_arn" {
  value = module.eks_node_role.role_arn
}

output "eks_cluster_ca_data" {
  sensitive = true
  value     = module.eks_cluster.cluster_ca_data
}

output "eks_secrets_kms_key_arn" {
  value = module.eks_cluster.effective_secrets_kms_key_arn
}

output "eks_access_entry_principals" {
  value = module.aws_auth.access_entry_principals
}

output "cloudwatch_dashboard_name" {
  value = module.cloudwatch.dashboard_name
}

output "cloudwatch_api_error_alarm_name" {
  value = module.cloudwatch.api_error_alarm_name
}

output "cloudwatch_failed_nodes_alarm_name" {
  value = module.cloudwatch.failed_nodes_alarm_name
}

output "cloudwatch_node_cpu_alarm_name" {
  value = module.cloudwatch.node_cpu_alarm_name
}

output "cloudwatch_node_memory_alarm_name" {
  value = module.cloudwatch.node_memory_alarm_name
}

output "cloudwatch_pending_pods_alarm_name" {
  value = module.cloudwatch.pending_pods_alarm_name
}

output "cloudwatch_pod_restarts_alarm_name" {
  value = module.cloudwatch.pod_restarts_alarm_name
}

output "eks_cloudwatch_observability_addon_arn" {
  value = module.eks_addons.cloudwatch_observability_addon_arn
}

output "eks_argocd_capability_arn" {
  value = module.eks_capabilities.argocd_capability_arn
}

output "eks_argocd_capability_version" {
  value = module.eks_capabilities.argocd_capability_version
}

output "eks_argocd_server_url" {
  value = module.eks_capabilities.argocd_server_url
}

output "eks_argocd_idc_managed_application_arn" {
  value = module.eks_capabilities.argocd_idc_managed_application_arn
}

output "eks_argocd_capability_role_arn" {
  value = module.eks_capabilities.argocd_capability_role_arn
}
