# AlgoHive x PLANK — Infrastructure AWS + GitOps Kubernetes

> Projet académique — Mastère Infrastructures, Sécurité & Cloud  
> Déploiement d'**AlgoHive** sur **AWS EKS** avec **Terraform**, **ArgoCD** managé par EKS capability, **Kustomize** et **GitHub Actions**.

---

## Contexte

Ce dépôt est le point d'entrée principal du projet **AlgoHive x PLANK**.

Il regroupe deux couches complémentaires :

1. une couche **infrastructure** qui provisionne AWS, le réseau, EKS, les addons et la capability ArgoCD avec Terraform ;
2. une couche **applicative GitOps** qui déploie AlgoHive sur le cluster via ArgoCD et Kustomize.

L'objectif de ce README est de présenter la vue d'ensemble du dépôt, d'expliquer le flux complet de déploiement et d'indiquer comment les différents workflows GitHub Actions s'articulent.

---

## Architecture globale

```text
                    ┌────────────────────────────────────────────┐
                    │               GitHub Repo                  │
                    │              eks-ec2-tf                   │
                    │                                            │
                    │  Terraform            k8s-v2/              │
                    │  + GHA infra          + ArgoCD app-of-apps │
                    └────────────────────────────────────────────┘
                                      │
                                      │
                     ┌────────────────┴────────────────┐
                     │                                 │
                     ▼                                 ▼
        ┌─────────────────────────┐       ┌─────────────────────────┐
        │ GitHub Actions          │       │ GitHub Actions          │
        │ terraform-*             │       │ argocd-bootstrap        │
        │                         │       │ app-refresh-latest      │
        └─────────────┬───────────┘       └─────────────┬───────────┘
                      │                                 │
                      └──────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌────────────────────────────────────────────┐
                  │             AWS EKS / eu-west-1           │
                  │                                            │
                  │  Capability ArgoCD                         │
                  │  Namespace: argocd                         │
                  │                                            │
                  │  Namespace: algohive                       │
                  │  - Postgres                                │
                  │  - Redis                                   │
                  │  - algohive-server                         │
                  │  - algohive-client                         │
                  │  - beehub                                  │
                  │  - beeapi-server-{tlse,mpl,lyon,staging}   │
                  └────────────────────────────────────────────┘
```

---

## Ce que fait ce dépôt

### Couche infrastructure

- Provisionnement du réseau AWS : VPC, subnets, Internet Gateway, NAT Gateway, tables de routage
- Provisionnement EKS
- Création des rôles IAM cluster et nodes
- Installation des addons EKS
- Création de la capability **AWS-managed ArgoCD**
- Configuration des accès EKS
- Mise en place de dashboards et alarmes CloudWatch

### Couche applicative

- Déploiement GitOps via **ArgoCD App of Apps**
- Organisation Kustomize avec `base/` et `overlays/`
- Déploiement ordonné avec `sync-wave`
- Gestion des secrets applicatifs via **GitHub Secrets -> kubeseal -> SealedSecret runtime**
- Refresh applicatif simple via `kubectl rollout restart` pour les images `latest`

---

## Structure du dépôt

```text
eks-ec2-tf/
├── .github/workflows/          # CI/CD Terraform + bootstrap ArgoCD + refresh app
├── aws/                        # Modules Terraform AWS
├── docs/                       # Documentation technique et d'exploitation
├── k8s-v2/
│   ├── argocd/                 # Application racine + Applications ArgoCD
│   ├── base/                   # Manifestes de base
│   └── overlays/               # Variantes de déploiement
├── README.md                   # Vue d'ensemble du projet
├── README_infra.md             # Documentation dédiée à Terraform / AWS / EKS
└── README_app.md               # Documentation dédiée à Kubernetes / ArgoCD / AlgoHive
```

---

## Flux de déploiement retenu

Le fonctionnement actuel du PoC suit ce cycle :

### 1. Provisionnement de l'infrastructure

Le workflow Terraform :

- crée le cluster EKS ;
- crée la capability ArgoCD ;
- prépare la fondation réseau, IAM et observabilité.

### 2. Bootstrap GitOps du cluster

Le workflow `argocd-bootstrap.yml` :

- récupère le kubeconfig du cluster ;
- attend que la capability ArgoCD soit disponible ;
- installe `sealed-secrets-controller` ;
- lit les secrets applicatifs depuis les **GitHub Secrets** ;
- génère un `SealedSecret` à la volée avec `kubeseal` ;
- applique `k8s-v2/argocd/app-of-apps.yaml`.

### 3. Synchronisation ArgoCD

ArgoCD déploie ensuite :

- `algohive-infrastructure` en wave `-2`
- `algohive-core` en wave `-1`
- `algohive-beeapi` en wave `0`

### 4. Refresh applicatif

Les manifests utilisent volontairement `latest`.

Pour faire simple dans le PoC :

- les Deployments utilisent `imagePullPolicy: Always`
- le workflow `app-refresh-latest.yml` relance les workloads avec `kubectl rollout restart`

---

## Workflows GitHub Actions

Les workflows disponibles dans `.github/workflows/` sont :

| Workflow | Rôle |
|---|---|
| `terraform-plan-main.yml` | Plan Terraform sur `main` |
| `terraform-apply-manual.yml` | Apply Terraform manuel |
| `terraform-destroy-manual.yml` | Destroy Terraform manuel |
| `argocd-bootstrap.yml` | Bootstrap ArgoCD + Sealed Secrets runtime |
| `app-refresh-latest.yml` | Redémarrage des workloads applicatifs qui utilisent `latest` |

### Détail du bootstrap ArgoCD

`argocd-bootstrap.yml` est la jonction entre la couche IaC et la couche GitOps.

Il garantit que :

- la capability ArgoCD est bien présente ;
- les secrets applicatifs ne sont pas stockés dans Git ;
- le cluster reçoit un `SealedSecret` valide ;
- l'Application racine ArgoCD est créée proprement.

### Détail du refresh applicatif

`app-refresh-latest.yml` redémarre :

- `algohive-server`
- `algohive-client`
- `beehub`
- `beeapi-server-tlse`
- `beeapi-server-mpl`
- `beeapi-server-lyon`
- `beeapi-server-staging`

Ce workflow ne build pas encore les images Docker, car ce dépôt ne contient pas les sources AlgoHive ni leurs Dockerfiles.

---

## Gestion des secrets

### Ce qui est important à retenir

- Le dépôt peut être **public** sans rendre les **GitHub Secrets** publics.
- Les secrets GitHub restent privés et sont uniquement consommés par les workflows GitHub Actions.
- Les secrets applicatifs Kubernetes ne sont **plus versionnés dans le repo**.

### Modèle retenu

Le flux de secrets est le suivant :

```text
GitHub Secrets
    │
    ▼
Workflow argocd-bootstrap
    │
    ├── kubectl create secret --dry-run
    ├── kubeseal
    └── kubectl apply
            │
            ▼
SealedSecret / Secret dans le cluster
```

### Secrets GitHub attendus

#### Infrastructure

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `TF_BACKEND_BUCKET`

#### Application

- `POSTGRES_PASSWORD`
- `JWT_SECRET`
- `DEFAULT_PASSWORD`
- `MAIL_PASSWORD`
- `CACHE_PASSWORD`
- `SECRET_KEY`
- `ADMIN_PASSWORD`

### Implication opérationnelle

Si le cluster est recréé ou si un secret applicatif change, il faut relancer le workflow `argocd-bootstrap.yml`.

---

## Démarrage rapide

### Prérequis

- Secrets GitHub configurés
- Bucket S3 du backend Terraform existant
- Variables Terraform renseignées
- Capability ArgoCD activée dans la stack Terraform

### Ordre recommandé

1. Lancer `terraform-apply-manual.yml`
2. Attendre que le cluster et la capability ArgoCD soient prêts
3. Lancer `argocd-bootstrap.yml`
4. Vérifier les Applications ArgoCD
5. Vérifier les pods AlgoHive

### Vérification

```bash
kubectl get applications -n argocd
kubectl get pods -n algohive
```

### Refresh applicatif

Quand une nouvelle image `latest` est disponible dans GHCR :

1. lancer `app-refresh-latest.yml`
2. vérifier les nouveaux pods

```bash
kubectl get pods -n algohive
```

---

## Documentation détaillée

| Document | Description |
|---|---|
| [README_infra.md](README_infra.md) | Terraform, modules AWS, capability ArgoCD, workflows infra |
| [README_app.md](README_app.md) | Kustomize, ArgoCD, secrets runtime, refresh applicatif |
| [docs/README-TECH.md](docs/README-TECH.md) | Architecture technique de `k8s-v2` |
| [docs/README-AWS.md](docs/README-AWS.md) | Déploiement AWS/EKS plus détaillé |
| [docs/README-STRESS.md](docs/README-STRESS.md) | Notes liées aux tests de charge et au HPA |

---

## État actuel du PoC

Ce dépôt est volontairement simple :

- ArgoCD est bien intégré à la capability EKS ;
- le bootstrap cluster -> secrets -> app-of-apps est automatisé ;
- les workloads applicatifs peuvent être rafraîchis automatiquement ;
- la partie **build Docker applicatif** n'est pas encore hébergée dans ce dépôt.

Autrement dit, le dépôt couvre aujourd'hui :

- l'infrastructure ;
- le bootstrap GitOps ;
- le déploiement Kubernetes ;
- le refresh des workloads.

---

## Références utiles

- Repo GitOps : `https://github.com/ShiftTechSecurity/eks-ec2-tf.git`
- Branche cible ArgoCD : `main`
- Namespace ArgoCD : `argocd`
- Namespace applicatif : `algohive`
