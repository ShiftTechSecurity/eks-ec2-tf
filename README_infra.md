# AlgoHive x PLANK - AWS EKS Terraform

Terraform repository for provisioning the AWS/EKS foundation used by AlgoHive x PLANK.

## What this layer provisions

- VPC, subnets, IGW, NAT gateways and routes
- IAM roles for the cluster and nodes
- EKS cluster
- EKS add-ons
- AWS-managed Argo CD capability
- EKS access entries
- CloudWatch dashboards and alarms

## Active Terraform modules

The root stack wires these modules:

- `aws/network/vpc`
- `aws/network/subnets`
- `aws/network/internet-gateway`
- `aws/network/nat-gateway`
- `aws/network/route-tables`
- `aws/iam/eks-cluster-role`
- `aws/iam/eks-node-role`
- `aws/eks/cluster`
- `aws/eks/addons`
- `aws/eks/capabilities`
- `aws/eks/aws-auth`
- `aws/observability/cloudwatch`

## Managed Argo CD capability

Terraform can create the EKS managed Argo CD capability via `aws_eks_capability`.

When enabled, Terraform configures:

- the IAM role used by the capability
- the Argo CD capability itself
- AWS Identity Center integration
- optional RBAC mappings
- optional VPC endpoint restrictions

Key variables in `terraform.tfvars`:

- `enable_eks_argocd_capability`
- `eks_argocd_idc_instance_arn`
- `eks_argocd_idc_region`
- `eks_argocd_rbac_role_mappings`
- `eks_argocd_vpce_ids`

## GitHub Actions

Workflows in `.github/workflows`:

- `terraform-plan-main.yml`
- `terraform-apply-manual.yml`
- `terraform-destroy-manual.yml`
- `argocd-bootstrap.yml`
- `app-refresh-latest.yml`

### Terraform workflows

- `terraform-plan-main.yml` runs on push to `main`
- `terraform-apply-manual.yml` applies manually
- `terraform-destroy-manual.yml` destroys manually with confirmation

### ArgoCD bootstrap workflow

`argocd-bootstrap.yml` is the bridge between Terraform and the GitOps layer.

It:

- configures kubeconfig on the target cluster
- waits for the managed Argo CD capability
- installs `sealed-secrets-controller`
- generates a runtime `SealedSecret` from GitHub Secrets
- applies `k8s-v2/argocd/app-of-apps.yaml`

### App refresh workflow

`app-refresh-latest.yml` reconnects to the cluster and restarts the AlgoHive workloads that consume `latest`.

## Required GitHub Secrets

Infrastructure:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `TF_BACKEND_BUCKET`

Application bootstrap:

- `POSTGRES_PASSWORD`
- `JWT_SECRET`
- `DEFAULT_PASSWORD`
- `MAIL_PASSWORD`
- `CACHE_PASSWORD`
- `SECRET_KEY`
- `ADMIN_PASSWORD`

These secrets stay private even when the repository itself is public.

## Useful outputs

After apply:

```bash
terraform output eks_cluster_name
terraform output eks_cluster_endpoint
terraform output eks_argocd_server_url
terraform output cloudwatch_dashboard_name
```

## Useful command

```bash
aws eks update-kubeconfig --region eu-west-1 --name algohive-plank-dev
```
