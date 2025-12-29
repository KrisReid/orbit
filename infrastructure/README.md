# Orbit Infrastructure

This directory contains all infrastructure-as-code for deploying Orbit to Kubernetes.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
  - [Local Development](#local-development)
  - [Cloud Deployment (EKS/GKE)](#cloud-deployment-eksgke)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Deployment Methods](#deployment-methods)
- [Configuration Reference](#configuration-reference)
- [Troubleshooting](#troubleshooting)

---

## Overview

Orbit uses a **GitOps deployment model** where:

1. **Terraform** provisions cloud infrastructure (VPC, Kubernetes cluster, database, addons)
2. **ArgoCD** deploys and manages the application (syncs from Git repository)
3. **External Secrets Operator** syncs database credentials from cloud secret managers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Deployment Flow                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   1. INFRASTRUCTURE (Terraform)         2. APPLICATION (ArgoCD)             │
│   ┌───────────────────────────┐         ┌───────────────────────────┐       │
│   │ • VPC / Networking        │         │ • Watches Git repo        │       │
│   │ • EKS/GKE Cluster         │         │ • Deploys Helm chart      │       │
│   │ • RDS/CloudSQL Database   │         │ • Auto-syncs on changes   │       │
│   │ • ArgoCD Installation     │  ────▶  │ • Manages rollbacks       │       │
│   │ • External Secrets (ESO)  │         │                           │       │
│   │ • ClusterSecretStore      │         │                           │       │
│   │ • ExternalSecret          │         │                           │       │
│   └───────────────────────────┘         └───────────────────────────┘       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Local Development

Run Orbit on your local Kubernetes cluster (minikube, kind, Docker Desktop, or k3s):

```bash
# 1. Start local Kubernetes (example with minikube)
minikube start

# 2. Build local images
docker build -t orbit-backend:local ./backend
docker build -t orbit-frontend:local ./frontend

# 3. Load images into local cluster (minikube)
minikube image load orbit-backend:local
minikube image load orbit-frontend:local

# 4. Install the Helm chart with local values
helm dependency update ./infrastructure/helm/orbit
helm install orbit ./infrastructure/helm/orbit \
  -f ./infrastructure/helm/orbit/values-local.yaml

# 5. Add host entry (optional)
echo "127.0.0.1 orbit.local" | sudo tee -a /etc/hosts

# 6. Access the application
minikube tunnel  # Run in separate terminal
# Open: http://orbit.local
```

### Cloud Deployment (EKS/GKE)

#### Step 1: Deploy Infrastructure with Terraform

**For AWS EKS:**
```bash
cd infrastructure/terraform/environments/eks

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply

# Configure kubectl
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw region)
```

**For GCP GKE:**
```bash
cd infrastructure/terraform/environments/gke

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy
terraform init
terraform plan
terraform apply

# Configure kubectl (command from terraform output)
$(terraform output -raw kubeconfig_command)
```

#### Step 2: Deploy Application with ArgoCD

After Terraform completes, deploy the ArgoCD Application:

```bash
# Edit the overlay with your configuration
# - Update repoURL to your Git repository
# - Update ingress.host to your domain
# - Update image repositories to your container registry
vi infrastructure/argocd/overlays/production/application-patch.yaml

# Apply the ArgoCD Application
kustomize build infrastructure/argocd/overlays/production | kubectl apply -f -

# Check status
kubectl get applications -n argocd
```

#### Step 3: Access ArgoCD UI

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open https://localhost:8080 (username: admin)
```

---

## Architecture

### Cloud Infrastructure (Terraform Provisions)

| Resource | AWS (EKS) | GCP (GKE) |
|----------|-----------|-----------|
| VPC/Network | VPC, Subnets, NAT Gateway | VPC, Subnet, Cloud NAT |
| Kubernetes | EKS with Managed Node Groups | GKE with Node Pools |
| Database | RDS PostgreSQL | Cloud SQL PostgreSQL |
| Secrets | AWS Secrets Manager | GCP Secret Manager |
| Ingress | nginx-ingress + NLB | nginx-ingress |
| TLS | cert-manager + Let's Encrypt | cert-manager + Let's Encrypt |
| GitOps | ArgoCD + External Secrets | ArgoCD + External Secrets |

### GitOps Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Git Repo      │───▶│    ArgoCD       │───▶│   Kubernetes    │
│   (main/dev)    │    │   (watches)     │    │   (deploys)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ External Secrets│
                       │   Operator      │
                       └────────┬────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Cloud Secret    │
                       │ Manager         │
                       │ (AWS/GCP)       │
                       └─────────────────┘
```

### Secrets Flow

1. **Terraform** creates database and generates password
2. **Password** is stored in cloud secret manager (AWS Secrets Manager / GCP Secret Manager)
3. **External Secrets Operator** uses cloud IAM (IRSA/Workload Identity) to authenticate
4. **ExternalSecret** resource syncs the password to a Kubernetes Secret
5. **Orbit backend** mounts the secret and connects to the database

---

## Directory Structure

```
infrastructure/
├── README.md                      # This file
├── argocd/                        # ArgoCD Application definitions
│   ├── base/                      # Base Application manifest
│   │   ├── application.yaml
│   │   └── kustomization.yaml
│   └── overlays/                  # Environment-specific patches
│       ├── production/            # Production config
│       │   ├── application-patch.yaml
│       │   └── kustomization.yaml
│       └── staging/               # Staging config
│           ├── application-patch.yaml
│           └── kustomization.yaml
├── helm/orbit/                    # Helm chart for Orbit
│   ├── Chart.yaml
│   ├── values.yaml                # Default values
│   ├── values-local.yaml          # Local development values
│   ├── charts/                    # Dependencies (PostgreSQL)
│   └── templates/                 # Kubernetes manifest templates
└── terraform/
    ├── environments/              # Cloud-specific root modules
    │   ├── eks/                   # AWS EKS deployment
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── gitops-variables.tf
    │   │   ├── outputs.tf
    │   │   ├── versions.tf
    │   │   └── terraform.tfvars.example
    │   └── gke/                   # GCP GKE deployment
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── gitops-variables.tf
    │       ├── outputs.tf
    │       ├── versions.tf
    │       └── terraform.tfvars.example
    └── modules/                   # Reusable Terraform modules
        ├── database-aws/          # RDS PostgreSQL
        ├── database-gcp/          # Cloud SQL PostgreSQL
        ├── eks/                   # EKS cluster
        ├── gke/                   # GKE cluster
        ├── gitops-aws/            # ClusterSecretStore + ExternalSecret (AWS)
        ├── gitops-gcp/            # ClusterSecretStore + ExternalSecret (GCP)
        ├── kubernetes-addons/     # nginx-ingress, cert-manager, ArgoCD, ESO
        ├── vpc-aws/               # AWS VPC
        └── vpc-gcp/               # GCP VPC
```

---

## Deployment Methods

### Method 1: Local Development (Docker Compose)

Best for: Individual developers, quick testing

```bash
# Run everything locally with Docker Compose
docker compose up -d

# Access at http://localhost
```

See [SELF-HOSTING.md](../docs/SELF-HOSTING.md) for Docker Compose deployment details.

### Method 2: Local Kubernetes (Helm)

Best for: Testing Kubernetes deployments locally

```bash
helm install orbit ./infrastructure/helm/orbit \
  -f ./infrastructure/helm/orbit/values-local.yaml
```

### Method 3: Cloud Kubernetes (Terraform + ArgoCD)

Best for: Production deployments with GitOps

1. **Terraform** provisions infrastructure
2. **ArgoCD** manages application deployments
3. **External Secrets** syncs credentials from cloud secret managers

---

## Configuration Reference

### Helm Values

Key configuration in `values.yaml`:

```yaml
# Database options
postgresql:
  enabled: true  # Built-in PostgreSQL (local/simple deployments)

externalDatabase:
  enabled: false  # External database (cloud deployments)
  existingSecret: "orbit-db-credentials"
  existingSecretConnectionStringKey: "DATABASE_URL"

# Ingress
ingress:
  enabled: true
  className: nginx
  host: orbit.example.com
  tls:
    enabled: true
    secretName: orbit-tls

# Backend
backend:
  replicaCount: 2
  autoscaling:
    enabled: true
```

### Environment-Specific Configuration

| Setting | Local | Staging | Production |
|---------|-------|---------|------------|
| Replicas | 1 | 1 | 2+ |
| Database | Built-in PostgreSQL | Cloud SQL/RDS | Cloud SQL/RDS |
| TLS | Disabled | Let's Encrypt Staging | Let's Encrypt Prod |
| Auto-scaling | Disabled | Disabled | Enabled |
| Debug | true | true | false |

### Terraform Variables

See `terraform.tfvars.example` in each environment for all available options.

Key variables:

| Variable | Description |
|----------|-------------|
| `project_name` | Name prefix for all resources |
| `region` | Cloud region |
| `enable_gitops_bootstrap` | Create SecretStore and ExternalSecret |
| `letsencrypt_email` | Email for Let's Encrypt certificates |

---

## Troubleshooting

### ArgoCD Application Not Syncing

```bash
# Check application status
kubectl get applications -n argocd

# View detailed status
kubectl describe application orbit -n argocd

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Force sync
kubectl patch application orbit -n argocd --type merge \
  -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {}}}'
```

### External Secrets Not Syncing

```bash
# Check ExternalSecret status
kubectl get externalsecrets -n orbit

# View detailed status
kubectl describe externalsecret orbit-db-credentials -n orbit

# Check if Kubernetes secret was created
kubectl get secret orbit-db-credentials -n orbit

# Check ESO logs
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

### Database Connection Issues

```bash
# Check backend logs
kubectl logs -l app.kubernetes.io/component=backend -n orbit

# Verify secret contents (base64 encoded)
kubectl get secret orbit-db-credentials -n orbit -o yaml

# Test database connectivity from a debug pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql "$(kubectl get secret orbit-db-credentials -n orbit -o jsonpath='{.data.DATABASE_URL}' | base64 -d)"
```

### Ingress Not Working

```bash
# Check ingress resource
kubectl get ingress -n orbit

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Check if TLS certificate is ready
kubectl get certificate -n orbit
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| ImagePullBackOff | Wrong image repository | Update image repository in ArgoCD overlay |
| CrashLoopBackOff | Missing environment variables | Check ExternalSecret is synced |
| 503 Service Unavailable | Pods not ready | Check pod logs and readiness probes |
| Certificate not ready | DNS not configured | Point DNS to ingress IP/hostname |

---

## Additional Resources

- [Self-Hosting Guide](../docs/SELF-HOSTING.md) - Docker Compose and advanced deployment options
- [Architecture Guide](../docs/architecture.md) - Application architecture details
- [Contributing Guide](../CONTRIBUTING.md) - Development workflow
