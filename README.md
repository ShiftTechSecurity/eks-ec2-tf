# AlgoHive x PLANK - AWS EKS Terraform

Terraform repository for provisioning a production-style AWS EKS foundation for the AlgoHive x PLANK project.

## Why this project exists

This repo provides a repeatable, auditable way to stand up core platform infrastructure for EKS workloads:

- Network baseline (VPC, subnets, IGW, NAT, routes)
- EKS cluster (Auto Mode compatible)
- IAM roles for cluster and nodes
- EKS access entries (`API` auth mode)
- Optional EKS managed Argo CD capability with AWS Identity Center integration
- CloudWatch dashboard and alarms
- CI pipelines for plan/apply/destroy

## Current architecture

Active module composition is in `05-main.tf`:

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

## AWS Identity Center (SSO) and managed Argo CD

This repo supports AWS-managed Argo CD for EKS via `aws_eks_capability` in `aws/eks/capabilities`.

When enabled, Terraform configures:

- an IAM role assumed by `capabilities.eks.amazonaws.com`
- the EKS Argo CD capability (`type = "ARGOCD"`)
- Identity Center (AWS IDC/SSO) integration for Argo CD auth
- optional RBAC mappings (IDC user/group IDs -> Argo CD roles)
- optional VPC endpoint restrictions

Key variables in `terraform.tfvars`:

- `enable_eks_argocd_capability`
- `eks_argocd_idc_instance_arn`
- `eks_argocd_idc_region`
- `eks_argocd_rbac_role_mappings`
- `eks_argocd_vpce_ids`

Minimal example:

```hcl
enable_eks_argocd_capability = true

eks_argocd_idc_instance_arn = "arn:aws:sso:::instance/ssoins-xxxxxxxxxxxxxxxx"
eks_argocd_idc_region       = "eu-west-1"

eks_argocd_rbac_role_mappings = [
  {
    role          = "ADMIN"
    identity_type = "SSO_GROUP"
    identity_id   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
]
```

Important behavior:

- If `enable_eks_argocd_capability = false`, Terraform will plan removal of Argo CD capability resources if they already exist in state.

## State backend

Remote state is S3 (see `01-backend.tf`):

- bucket: `tfstate-bucket-plank`
- key: `eks-ec2-tf/terraform.tfstate`
- region: `eu-west-1`
- lockfile: enabled (`use_lockfile = true`)

## Prerequisites

- Terraform `>= 1.10.0, < 2.0.0`
- AWS credentials with permissions for VPC/EKS/IAM/CloudWatch
- AWS CLI configured locally
- Existing S3 backend bucket

## Local workflow

1. Initialize

```bash
terraform init
```

2. Format and validate

```bash
terraform fmt -recursive
terraform validate
```

3. Plan

```bash
terraform plan
```

4. Apply

```bash
terraform apply
```

5. Configure kubeconfig

```bash
aws eks update-kubeconfig --region eu-west-1 --name algohive-plank-dev
kubectl get nodes
```

## CI/CD (GitHub Actions)

Workflows in `.github/workflows`:

- `terraform-plan-main.yml`
- `terraform-apply-manual.yml`
- `terraform-destroy-manual.yml`

### Plan on push (`main`)

Runs:

- `terraform init` (backend config from secrets)
- `terraform fmt -check -recursive`
- `tflint`
- `tfsec` (soft-fail)
- `terraform validate`
- `terraform plan -out=tfplan`
- artifact upload (`tfplan`, `tfplan.txt`)

### Manual apply

`workflow_dispatch` with optional `git_ref`.

Runs:

- `terraform init`
- fmt, lint, validate
- `terraform plan -out=tfplan`
- `terraform apply -auto-approve tfplan`

### Manual destroy

`workflow_dispatch` with `confirm_destroy = DESTROY` safeguard.

Runs:

- `terraform init`
- `terraform validate`
- `terraform plan -destroy`
- `terraform destroy -auto-approve`

### Required GitHub secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `TF_BACKEND_BUCKET`

## Initial scaffold script (`dir-init.ps1`)

`dir-init.ps1` is a bootstrap helper for creating an initial Terraform folder/file skeleton with your standard headers.

Use it only for greenfield scaffolding.

Why: it writes template content into root Terraform files (`03-locals.tf`, `04-variables.tf`, `05-main.tf`, `06-outputs.tf`). Running it on an existing implementation can overwrite in-progress configuration.

## Useful outputs

After apply:

```bash
terraform output eks_cluster_name
terraform output eks_cluster_endpoint
terraform output cloudwatch_dashboard_name
```

## Notes

- This repo currently uses one root stack and one backend state key.
- Environment subfolders were intentionally removed from the active workflow.
