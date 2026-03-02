# k3s-infra

Infrastructure GitOps pour k3s sur Proxmox avec Cloudflare Tunnel.

## Architecture

```
Internet → Cloudflare (DNS + Proxy) → Cloudflare Tunnel → cloudflared (pod k8s) → nginx-svc → nginx (NFS/CephFS)
```

## Structure

```
k3s-infra/
├── terraform/                    # Infrastructure Cloudflare
│   ├── main.tf                   # Tunnel, DNS, secret k8s
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example  ← copier en terraform.tfvars (non commité)
├── k8s/                          # Manifestes Kubernetes (gérés par ArgoCD)
│   ├── namespace.yaml
│   ├── cloudflared.yaml          # Daemon du tunnel
│   ├── nginx.yaml                # Deployment + Service
│   └── pvc.yaml                  # Stockage CephFS
└── argocd-app.yaml               # Application ArgoCD
```

## Ordre d'exécution (première fois)

### 1. Terraform — Cloudflare + secret k8s

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec tes valeurs
terraform init
terraform apply
```

Cela crée :
- Le tunnel Cloudflare Zero Trust
- Le CNAME `test.ve2fpd.com` → tunnel
- Les ingress rules du tunnel
- Le secret `tunnel-token` dans le namespace `cloudflare-test`

### 2. ArgoCD — Installation

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que les pods soient prêts
kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=120s
```

### 3. ArgoCD — Déployer l'application

```bash
kubectl apply -f argocd-app.yaml
```

ArgoCD va synchroniser automatiquement le dossier `k8s/` depuis Git.

## Workflow quotidien

```
Modifier un YAML dans k8s/  →  git commit + push  →  ArgoCD déploie automatiquement
```

Pour mettre à jour le site web : déposer un `index.html` sur le volume CephFS monté.

## Prérequis

- k3s installé et `~/.kube/config` configuré
- StorageClass `ceph-cephfs` disponible (adapter `pvc.yaml` sinon)
- Token Cloudflare avec permissions : `Zone:DNS:Edit` + `Account:Cloudflare Tunnel:Edit`

## Sécurité

- `terraform.tfvars` est dans `.gitignore` — ne jamais committer les secrets
- Le token du tunnel transite uniquement via un secret Kubernetes
