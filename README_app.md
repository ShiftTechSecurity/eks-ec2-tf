# AlgoHive x PLANK - Application Layer

Kubernetes GitOps layer for deploying AlgoHive on AWS EKS with ArgoCD.

## What is deployed

- `algohive-client`
- `algohive-server`
- `beehub`
- `beeapi-server-tlse`
- `beeapi-server-mpl`
- `beeapi-server-lyon`
- `beeapi-server-staging`
- `algohive-db`
- `algohive-cache`
- `algohive-monitoring`
- `algohive-kubeview`

## Stack

- Kubernetes on AWS EKS
- ArgoCD `app-of-apps`
- Kustomize `base/overlays`
- AWS ALB Ingress
- Bitnami Sealed Secrets

## ArgoCD structure

`k8s-v2/argocd/app-of-apps.yaml` creates three Applications:

- `algohive-infrastructure`
- `algohive-core`
- `algohive-beeapi`

Deployment order is enforced with sync waves:

- `-2` infrastructure
- `-1` core
- `0` beeapi

The ArgoCD Applications now point to:

- repo: `https://github.com/ShiftTechSecurity/AlgoHive-x-Plank-wEKS.git`
- branch: `main`

## Secrets model

Secrets are no longer stored in Git.

Current flow:

1. GitHub Secrets store the application secrets.
2. `argocd-bootstrap.yml` creates a Kubernetes `Secret` in memory.
3. The workflow seals it with `kubeseal`.
4. The resulting `SealedSecret` is applied directly to the cluster.

This means:

- no plaintext secret in the repo
- no committed `sealed-secret.yaml`
- rerun bootstrap if the cluster is recreated or if app secrets change

## Image refresh model

The manifests intentionally keep `latest`.

To make this reliable enough for the PoC:

- deployments use `imagePullPolicy: Always`
- `app-refresh-latest.yml` performs `kubectl rollout restart` on the workloads

This repository does not currently contain the AlgoHive application source code or Dockerfiles, so the app workflow implemented here refreshes the cluster workloads rather than building images locally.

## Bootstrap flow

1. Run the Terraform workflow to create EKS and the managed ArgoCD capability.
2. Run `argocd-bootstrap.yml`.
3. Verify:

```bash
kubectl get applications -n argocd
kubectl get pods -n algohive
```

## Refresh flow

When new GHCR `latest` images are available, run:

- `app-refresh-latest.yml`

It restarts:

- `algohive-server`
- `algohive-client`
- `beehub`
- `beeapi-server-tlse`
- `beeapi-server-mpl`
- `beeapi-server-lyon`
- `beeapi-server-staging`
