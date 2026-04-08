# AlgoHive x PLANK

> YDAYS Ynov Project
> AWS EKS infrastructure + GitOps Kubernetes deployment for the AlgoHive platform.

<p align="center">
  <img src="https://raw.githubusercontent.com/AlgoHive-Coding-Puzzles/Ressources/refs/heads/main/images/algohive-logo.png" alt="AlgoHive logo" width="220" />
</p>

AlgoHive is a self-hosted coding game platform designed to publish, organize and solve developer puzzles.
This repository is the deployment backbone of the **AlgoHive x PLANK** project: it provisions the AWS foundation with Terraform, bootstraps AWS-managed ArgoCD on EKS, and deploys the AlgoHive workloads through GitOps.

---

## Project Scope

This repository combines two complementary layers:

1. **Infrastructure as Code**
   Provisioning of AWS networking, IAM, EKS, observability and the EKS managed ArgoCD capability.
2. **Application GitOps**
   Deployment of AlgoHive, BeeHub and BeeAPI services with Kustomize + ArgoCD `app-of-apps`.

In practice, this repo is the junction point between:

- the **AWS / Terraform** foundation,
- the **Kubernetes / ArgoCD** application layer,
- the **GitHub Actions** operational workflows used for bootstrap and refresh.

---

## Visual Overview

<p align="center">
  <img src="https://raw.githubusercontent.com/AlgoHive-Coding-Puzzles/Documentation/refs/heads/main/docs/AlgoHiveArchi.drawio.png" alt="AlgoHive architecture overview" width="900" />
</p>

---

## What Is Deployed

### Infrastructure layer

- VPC, public/private subnets, Internet Gateway, NAT Gateway and route tables
- IAM roles for EKS cluster and nodes
- Amazon EKS cluster in `eu-west-1`
- EKS add-ons and observability
- AWS-managed ArgoCD capability
- CloudWatch dashboards and alarms
- Subnet tags required for **EKS Auto Mode ALB** provisioning

### Application layer

- `algohive-server`
- `algohive-client`
- `beehub`
- `beeapi-server-tlse`
- `beeapi-server-mpl`
- `beeapi-server-lyon`
- `beeapi-server-staging`
- `algohive-db`
- `algohive-cache`

---

## Repository Structure

```text
AlgoHive-x-Plank-wEKS/
├── .github/workflows/          # Terraform, ArgoCD bootstrap, app refresh
├── aws/                        # Terraform modules
├── docs/                       # Technical and exploitation notes
├── k8s-v2/
│   ├── argocd/                 # Root app + ArgoCD applications
│   ├── base/                   # Base manifests
│   └── overlays/               # Production overlays
├── quick_start.md              # Demo-oriented runbook
├── README.md                   # Global overview
├── README_infra.md             # Infrastructure details
└── README_app.md               # Application / GitOps details
```

---

## Deployment Flow

The current PoC follows this chain:

```text
GitHub Secrets
    ->
GitHub Actions Terraform
    ->
AWS EKS + managed ArgoCD capability
    ->
GitHub Actions argocd-bootstrap
    ->
Runtime SealedSecret generation
    ->
ArgoCD app-of-apps
    ->
AlgoHive workloads on Kubernetes
```

### 1. Infrastructure provisioning

The Terraform workflows provision:

- networking,
- IAM,
- EKS,
- add-ons,
- the managed ArgoCD capability,
- observability resources.

### 2. ArgoCD bootstrap

The `argocd-bootstrap.yml` workflow:

- connects to the EKS cluster,
- waits for the managed ArgoCD capability,
- installs `sealed-secrets-controller`,
- generates a runtime `SealedSecret` from GitHub Secrets,
- applies `k8s-v2/argocd/app-of-apps.yaml`.

### 3. ArgoCD synchronization

ArgoCD deploys the application in three ordered blocks:

- `algohive-infrastructure`
- `algohive-core`
- `algohive-beeapi`

### 4. Application refresh

This PoC intentionally keeps the `latest` image tag.

To make that workable:

- deployments use `imagePullPolicy: Always`,
- `app-refresh-latest.yml` performs `kubectl rollout restart` on the live workloads.

---

## GitHub Actions

Available workflows:

| Workflow | Purpose |
|---|---|
| `terraform-plan-main.yml` | Terraform plan on `main` |
| `terraform-apply-manual.yml` | Manual Terraform apply |
| `terraform-destroy-manual.yml` | Manual Terraform destroy |
| `argocd-bootstrap.yml` | ArgoCD bootstrap + runtime SealedSecret |
| `app-refresh-latest.yml` | Workload refresh for `latest` images |

---

## Secrets Model

The repository can remain public without exposing GitHub Secrets.

Current model:

```text
GitHub Secrets
    ->
argocd-bootstrap.yml
    ->
kubectl create secret --dry-run
    ->
kubeseal
    ->
SealedSecret applied to cluster
    ->
Secret materialized in namespace algohive
```

### Required GitHub Secrets

Infrastructure:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `TF_BACKEND_BUCKET`

Application:

- `POSTGRES_PASSWORD`
- `JWT_SECRET`
- `DEFAULT_PASSWORD`
- `MAIL_PASSWORD`
- `CACHE_PASSWORD`
- `SECRET_KEY`
- `ADMIN_PASSWORD`

If the cluster is recreated, or if application secrets change, rerun `argocd-bootstrap.yml`.

---

## ArgoCD and Ingress Notes

Recent changes now align the deployment with **EKS Auto Mode**:

- `IngressClass` `alb` is created with controller `eks.amazonaws.com/alb`
- public/private subnets are tagged for ALB auto-discovery
- BeeHub has its own ingress
- AlgoHive main app uses an ALB ingress without requiring ownership of `algohive.dev`

To get the current public endpoints:

```bash
kubectl get ingress -n algohive -o wide
```

Current entry points are:

- `algohive-ingress` for the main web application
- `beehub-ingress` for BeeHub

Because ALB DNS names are generated by AWS, they can change if the ingress is recreated.

---

## Demo Access

### Public URLs

Get the live URLs with:

```bash
kubectl get ingress -n algohive -o wide
```

### Login credentials

Current deployed credentials:

- Username: `admin`
- Password: `AdminAlgoHive2026!`

### Fallback for demos

If AWS DNS is still propagating, use port-forward:

```bash
kubectl port-forward svc/algohive-client -n algohive 8088:80
kubectl port-forward svc/beehub -n algohive 8081:8081
```

Then open:

- `http://localhost:8088`
- `http://localhost:8081`

---

## BeeAPI Catalog Activation In BeeHub

BeeHub requires the API key of each BeeAPI instance to manually activate catalogs.

Use the following commands to retrieve the live keys from the running pods:

```bash
kubectl exec -it -n algohive beeapi-server-tlse-f7b7b45f7-bffqx -- /bin/sh -c "cat /app/data/.api-key"
kubectl exec -it -n algohive beeapi-server-mpl-78575c4cd6-v8ptp -- /bin/sh -c "cat /app/data/.api-key"
kubectl exec -it -n algohive beeapi-server-lyon-6986bc68cf-zbrbx -- /bin/sh -c "cat /app/data/.api-key"
kubectl exec -it -n algohive beeapi-server-staging-d5d456c89-bg5tf -- /bin/sh -c "cat /app/data/.api-key"
```

These keys then have to be entered manually in BeeHub to activate the corresponding catalogs.

For a more robust operator workflow, you can also resolve the pods dynamically:

```bash
kubectl exec -it -n algohive $(kubectl get pod -n algohive -l app=beeapi-server-tlse -o jsonpath="{.items[0].metadata.name}") -- /bin/sh -c "cat /app/data/.api-key"
kubectl exec -it -n algohive $(kubectl get pod -n algohive -l app=beeapi-server-mpl -o jsonpath="{.items[0].metadata.name}") -- /bin/sh -c "cat /app/data/.api-key"
kubectl exec -it -n algohive $(kubectl get pod -n algohive -l app=beeapi-server-lyon -o jsonpath="{.items[0].metadata.name}") -- /bin/sh -c "cat /app/data/.api-key"
kubectl exec -it -n algohive $(kubectl get pod -n algohive -l app=beeapi-server-staging -o jsonpath="{.items[0].metadata.name}") -- /bin/sh -c "cat /app/data/.api-key"
```

---

## Quick Start

### Minimal sequence

1. Create GitHub Secrets
2. Run `terraform-plan-main.yml`
3. Run `terraform-apply-manual.yml`
4. Run `argocd-bootstrap.yml`
5. Check ArgoCD applications
6. Check AlgoHive pods
7. Run `app-refresh-latest.yml` if needed

### Verification commands

```bash
kubectl get applications -n argocd
kubectl get pods -n algohive
kubectl get ingress -n algohive -o wide
```

For the full demo runbook, use [quick_start.md](quick_start.md).

---

## Current PoC Status

This repository currently covers:

- infrastructure provisioning on AWS,
- EKS + managed ArgoCD capability,
- GitOps bootstrap with runtime sealed secrets,
- Kubernetes deployment of AlgoHive components,
- ALB exposure for the web interfaces,
- operational refresh of workloads using `latest`.

This repository does **not** currently contain the AlgoHive application source code or Dockerfiles, so it does not build the platform images locally.

---

## Detailed Documentation

| Document | Description |
|---|---|
| [README_infra.md](README_infra.md) | Terraform, AWS, EKS and managed ArgoCD capability |
| [README_app.md](README_app.md) | ArgoCD, Kustomize, secrets runtime and workload refresh |
| [quick_start.md](quick_start.md) | Demo-oriented startup and troubleshooting guide |
| [docs/README-TECH.md](docs/README-TECH.md) | Additional Kubernetes technical notes |
| [docs/README-AWS.md](docs/README-AWS.md) | Additional AWS and EKS notes |
| [docs/README-STRESS.md](docs/README-STRESS.md) | Stress and load-testing notes |

---

## Upstream AlgoHive References

This deployment project is based on the broader AlgoHive ecosystem:

- AlgoHive GitHub organization: https://github.com/AlgoHive-Coding-Puzzles
- AlgoHive website: https://algohive.dev

Key public components highlighted upstream include:

- AlgoHive Client / API
- BeeAPI
- BeeHub
- HiveCraft
- BeeToFlow

---

## Practical References

- GitOps repository: `https://github.com/ShiftTechSecurity/AlgoHive-x-Plank-wEKS.git`
- ArgoCD target branch: `main`
- AWS region: `eu-west-1`
- ArgoCD namespace: `argocd`
- Application namespace: `algohive`
