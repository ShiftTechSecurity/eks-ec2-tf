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

resource "aws_iam_role" "argocd_capability" {
  count = var.enable_argocd_capability ? 1 : 0

  name = "${var.project_name}-eks-argocd-capability-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "capabilities.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "time_sleep" "wait_for_role_propagation" {
  count = var.enable_argocd_capability ? 1 : 0

  create_duration = var.argocd_role_propagation_wait

  depends_on = [aws_iam_role.argocd_capability]
}

resource "aws_eks_capability" "argocd" {
  count = var.enable_argocd_capability ? 1 : 0

  cluster_name              = var.cluster_name
  type                      = "ARGOCD"
  capability_name           = var.argocd_capability_name
  role_arn                  = aws_iam_role.argocd_capability[0].arn
  delete_propagation_policy = var.argocd_delete_propagation_policy

  configuration {
    argo_cd {
      namespace = var.argocd_namespace

      aws_idc {
        idc_instance_arn = var.argocd_idc_instance_arn
        idc_region       = coalesce(var.argocd_idc_region, var.aws_region)
      }

      dynamic "rbac_role_mapping" {
        for_each = var.argocd_rbac_role_mappings
        content {
          role = rbac_role_mapping.value.role

          identity {
            type = rbac_role_mapping.value.identity_type
            id   = rbac_role_mapping.value.identity_id
          }
        }
      }

      dynamic "network_access" {
        for_each = length(var.argocd_vpce_ids) > 0 ? [1] : []
        content {
          vpce_ids = var.argocd_vpce_ids
        }
      }
    }
  }

  depends_on = [time_sleep.wait_for_role_propagation]

  tags = var.tags
}
