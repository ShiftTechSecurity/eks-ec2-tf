enable_eks_argocd_capability = true
eks_endpoint_public_access = true

eks_argocd_idc_instance_arn = "arn:aws:sso:::instance/ssoins-68040d02a7828ad3"
eks_argocd_idc_region       = "eu-west-1"

eks_argocd_rbac_role_mappings = [
  {
    role          = "ADMIN"
    identity_type = "SSO_GROUP"
    identity_id   = "f2d50484-e021-70fc-2293-9ffc15de6c0f"
  }
]
