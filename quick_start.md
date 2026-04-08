# Quick Start — Démo AlgoHive x PLANK

> Guide opératoire pour lancer et démontrer le projet rapidement.
> Objectif : suivre un enchaînement simple demain matin sans improvisation.

> Ce guide est référencé depuis le README principal :
> [README.md](README.md)

---

## Vue express

Si tu veux la version la plus simple possible :

1. Créer les secrets GitHub
2. Lancer `terraform-plan-main.yml`
3. Lancer `terraform-apply-manual.yml`
4. Lancer `argocd-bootstrap.yml`
5. Vérifier `kubectl get applications -n argocd`
6. Vérifier `kubectl get pods -n algohive`
7. Si besoin, lancer `app-refresh-latest.yml`

En une phrase :

`GitHub Secrets -> Terraform Plan -> Terraform Apply -> ArgoCD Bootstrap -> Vérification cluster -> Refresh app`

---

## Objectif de la démo

Montrer que le projet couvre bien toute la chaîne suivante :

1. infrastructure AWS/EKS provisionnée avec Terraform ;
2. capability ArgoCD managée par EKS disponible ;
3. bootstrap GitOps du cluster via GitHub Actions ;
4. déploiement ordonné des applications AlgoHive via ArgoCD ;
5. refresh applicatif simple des workloads qui utilisent `latest`.

---

## Informations importantes

- Région AWS active dans la stack Terraform : `eu-west-1`
- Nom de cluster par défaut dans les workflows : `algohive-plank-dev`
- Namespace ArgoCD : `argocd`
- Namespace applicatif : `algohive`
- Repo GitOps utilisé par ArgoCD : `https://github.com/ShiftTechSecurity/eks-ec2-tf.git`
- Branche cible ArgoCD : `main`
- Pour la démo, l'accès web peut se faire directement via les `ADDRESS` des Ingress AWS
- Il n'est pas nécessaire de posséder `algohive.dev` pour la démo si les règles Ingress sont sans `host`

> ⚠️ Certaines notes historiques dans `docs/` mentionnent encore `eu-west-3`. Pour la démo, suivre ce guide et la configuration active actuelle : `eu-west-1`.

> ℹ️ Les commandes ci-dessous restent majoritairement compatibles avec un terminal classique. En PowerShell, si une commande avec `grep` pose problème, utiliser `Select-String`.

---

## Ce qu'il faut vérifier avant la démo

### 1. GitHub Secrets

Vérifier que ces secrets existent dans le repo GitHub :

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

### 2. Workflows disponibles

Vérifier dans l'onglet GitHub Actions la présence de :

- `terraform-plan-main.yml`
- `terraform-apply-manual.yml`
- `terraform-destroy-manual.yml`
- `argocd-bootstrap.yml`
- `app-refresh-latest.yml`

### 3. Contexte local

Préparer un terminal avec :

```bash
aws --version
kubectl version --client
```

Configurer le kubeconfig si besoin :

```bash
aws eks update-kubeconfig --region eu-west-1 --name algohive-plank-dev
kubectl get nodes
```

---

## Ordre recommandé le jour J

### Étape 1 — Vérifier l'infrastructure

Si l'infrastructure est déjà en place :

```bash
aws eks update-kubeconfig --region eu-west-1 --name algohive-plank-dev
kubectl get nodes
```

Résultat attendu :

- le cluster répond ;
- au moins un ou plusieurs nodes sont `Ready`.

Si besoin de relancer l'infra :

- lancer le workflow GitHub Actions `terraform-apply-manual.yml`

Puis vérifier :

```bash
kubectl get nodes
```

---

### Étape 2 — Vérifier ArgoCD capability

Commande :

```bash
kubectl get ns argocd
kubectl get crd applications.argoproj.io
```

Résultat attendu :

- le namespace `argocd` existe ;
- la CRD `applications.argoproj.io` existe.

Si ce n'est pas le cas :

- attendre un peu après le workflow Terraform ;
- relancer ensuite `argocd-bootstrap.yml` seulement quand la capability est prête.

---

### Étape 3 — Lancer le bootstrap GitOps

Depuis GitHub Actions :

- lancer `argocd-bootstrap.yml`

Inputs recommandés :

- `git_ref`: `main`
- `cluster_name`: `algohive-plank-dev`
- `aws_region`: laisser vide si `AWS_REGION` est déjà bon dans les secrets

Ce workflow fait :

- connexion au cluster EKS ;
- attente de la capability ArgoCD ;
- installation de `sealed-secrets-controller` ;
- génération du `SealedSecret` depuis les GitHub Secrets ;
- application de `k8s-v2/argocd/app-of-apps.yaml`.

À vérifier ensuite :

```bash
kubectl get applications -n argocd
kubectl get sealedsecrets -n algohive
kubectl get secret algohive-secret -n algohive
```

Résultat attendu :

- `algohive-root`
- `algohive-infrastructure`
- `algohive-core`
- `algohive-beeapi`
- un `SealedSecret` dans `algohive`
- un `Secret` `algohive-secret` matérialisé dans le cluster

---

### Étape 4 — Vérifier le déploiement applicatif

Commandes :

```bash
kubectl get applications -n argocd
kubectl get pods -n algohive
kubectl get svc -n algohive
kubectl get ingress -n algohive
```

Résultat attendu :

- les Applications ArgoCD sont `Synced` et idéalement `Healthy`
- les pods passent en `Running`
- les services AlgoHive sont présents
- les Ingress ont une `ADDRESS` AWS

Pods attendus :

- `algohive-db`
- `algohive-cache`
- `algohive-server`
- `algohive-client`
- `beehub`
- `beeapi-server-tlse`
- `beeapi-server-mpl`
- `beeapi-server-lyon`
- `beeapi-server-staging`

Pour récupérer les URLs de démo :

```bash
kubectl get ingress -n algohive -o wide
```

Utiliser ensuite les valeurs du champ `ADDRESS` dans le navigateur :

- `algohive-ingress` pour l'application principale
- `beehub-ingress` pour BeeHub

> ℹ️ Ces noms DNS AWS sont générés automatiquement et peuvent changer si l'Ingress est recréé.

---

### Étape 5 — Démontrer le refresh applicatif

Si les images `latest` existent déjà dans GHCR, lancer :

- `app-refresh-latest.yml`

Ce workflow :

- se reconnecte au cluster ;
- exécute un `rollout restart` des déploiements applicatifs ;
- attend leur redémarrage.

Vérification :

```bash
kubectl get pods -n algohive
kubectl rollout status deployment/algohive-server -n algohive
kubectl rollout status deployment/algohive-client -n algohive
kubectl rollout status deployment/beehub -n algohive
```

Pour les BeeAPI :

```bash
kubectl rollout status deployment/beeapi-server-tlse -n algohive
kubectl rollout status deployment/beeapi-server-mpl -n algohive
kubectl rollout status deployment/beeapi-server-lyon -n algohive
kubectl rollout status deployment/beeapi-server-staging -n algohive
```

---

## Script de démo conseillé

Si tu veux un déroulé simple et fluide :

1. Présenter rapidement le dépôt :
   - Terraform pour l'infra
   - `k8s-v2` pour le GitOps
   - workflows GitHub Actions
2. Montrer que le cluster EKS existe :
   - `kubectl get nodes`
3. Montrer qu'ArgoCD capability est bien là :
   - `kubectl get ns argocd`
   - `kubectl get crd applications.argoproj.io`
4. Montrer le bootstrap GitOps :
   - interface GitHub Actions
   - workflow `argocd-bootstrap.yml`
5. Montrer l'état ArgoCD :
   - `kubectl get applications -n argocd`
6. Montrer les workloads :
   - `kubectl get pods -n algohive`
   - `kubectl get ingress -n algohive`
7. Montrer le refresh applicatif :
   - workflow `app-refresh-latest.yml`
   - puis `kubectl get pods -n algohive`

---

## Troubleshooting rapide

### Problème 1 — Le cluster n'est pas accessible

Symptômes :

- `kubectl get nodes` échoue
- `You must be logged in to the server`
- `context deadline exceeded`

À faire :

```bash
aws eks update-kubeconfig --region eu-west-1 --name algohive-plank-dev
kubectl get nodes
```

Si ça ne marche toujours pas :

- vérifier les credentials AWS locaux ;
- vérifier que le workflow Terraform a bien terminé ;
- vérifier que le cluster existe dans AWS.

---

### Problème 2 — ArgoCD capability pas encore prête

Symptômes :

- le workflow `argocd-bootstrap.yml` échoue sur l'attente de `applications.argoproj.io`

À faire :

```bash
kubectl get ns argocd
kubectl get crd applications.argoproj.io
```

Si absent :

- attendre encore 2 à 5 minutes ;
- relancer `argocd-bootstrap.yml`.

---

### Problème 3 — Le secret `algohive-secret` n'apparaît pas

Symptômes :

- `kubectl get secret algohive-secret -n algohive` ne retourne rien

À faire :

```bash
kubectl get pods -n kube-system
kubectl get sealedsecrets -n algohive
```

En PowerShell, filtre rapide possible :

```powershell
kubectl get pods -n kube-system | Select-String "sealed-secrets"
```

Vérifier :

- que `sealed-secrets-controller` est bien `Running`
- que tous les GitHub Secrets applicatifs sont bien définis

Puis :

- relancer `argocd-bootstrap.yml`

---

### Problème 4 — Une Application ArgoCD reste OutOfSync ou Degraded

Commandes utiles :

```bash
kubectl describe application algohive-root -n argocd
kubectl describe application algohive-infrastructure -n argocd
kubectl describe application algohive-core -n argocd
kubectl describe application algohive-beeapi -n argocd
```

Et :

```bash
kubectl get pods -n algohive
kubectl get events -n algohive --sort-by=.metadata.creationTimestamp
```

Causes probables :

- secret pas encore disponible ;
- PVC en attente ;
- pod qui crash ;
- Ingress ou service mal résolu.

---

### Problème 5 — L'Ingress n'a pas d'ADDRESS ou la page charge indéfiniment

Symptômes :

- `kubectl get ingress -n algohive` affiche une `ADDRESS` vide
- ou l'URL AWS ne répond pas encore

À vérifier :

```bash
kubectl get ingressclass
kubectl describe ingress algohive-ingress -n algohive
kubectl describe ingress beehub-ingress -n algohive
```

Points attendus :

- `IngressClass` `alb` présente
- événements `Successfully reconciled`
- subnets publics taggés pour l'ALB

Si les événements parlent de `couldn't auto-discover subnets` :

- vérifier les tags subnet AWS :
  - public : `kubernetes.io/role/elb=1`
  - private : `kubernetes.io/role/internal-elb=1`

Une fois l'`ADDRESS` visible :

- attendre encore 1 à 3 minutes pour la propagation DNS AWS
- puis ouvrir directement l'URL `http://<ADDRESS>`

---

### Problème 6 — Le refresh applicatif ne change rien

Symptômes :

- le workflow `app-refresh-latest.yml` termine mais aucun changement visible

À vérifier :

- les images GHCR `latest` ont-elles vraiment changé ?
- les pods ont-ils bien été recréés ?

Commandes :

```bash
kubectl get pods -n algohive
kubectl rollout history deployment/algohive-server -n algohive
```

Au minimum, pour la démo :

- montrer que le workflow sait redémarrer les déploiements ;
- montrer que `imagePullPolicy: Always` est bien présent dans les manifests.

---

## Commandes de secours utiles

```bash
kubectl get applications -n argocd
kubectl get pods -n algohive
kubectl get svc -n algohive
kubectl get ingress -n algohive
kubectl get secret algohive-secret -n algohive
kubectl get events -n algohive --sort-by=.metadata.creationTimestamp
```

---

## Résumé ultra-court pour demain matin

Si tu veux la version la plus compacte :

1. `terraform-apply-manual.yml` si nécessaire
2. `argocd-bootstrap.yml`
3. `kubectl get applications -n argocd`
4. `kubectl get pods -n algohive`
5. `app-refresh-latest.yml`
6. `kubectl get pods -n algohive`

Ce guide est volontairement orienté exploitation rapide, pas conception.
