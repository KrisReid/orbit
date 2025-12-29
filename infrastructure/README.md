# Orbit Infrastructure

This directory contains all infrastructure-as-code for deploying Orbit to Kubernetes (GKE or EKS) with GitOps.

## Directory Structure

```
infrastructure/
├── argocd/                    # ArgoCD Application definitions
│   ├── base/                  # Base Application manifest
│   └── overlays/              # Environment-specific patches
│       ├── production/        # Production (main branch, production namespace)
│       └── staging/           # Staging (develop branch, staging namespace)
├── helm/orbit/                # Helm chart for Orbit application
│   ├── templates/             # Kubernetes manifest templates
│   ├── values.yaml            # Default values
│   └── values-local.yaml      # Local development values
└── terraform/
    ├── environments/          # Cloud-specific configurations
    │   ├── eks/               # AWS EKS deployment
    │   └── gke/               # GCP GKE deployment
    └── modules/               # Reusable Terraform modules
        ├── database-aws/      # RDS PostgreSQL
        ├── database-gcp/      # Cloud SQL PostgreSQL
        ├── eks/               # EKS cluster
        ├── gke/               # GKE cluster
        ├── gitops-aws/        # External Secrets + ArgoCD for AWS
        ├── gitops-gcp/        # External Secrets + ArgoCD for GCP
        ├── kubernetes-addons/ # nginx-ingress, cert-manager, ArgoCD, ESO
        ├── vpc-aws/           # AWS VPC
        └── vpc-gcp/           # GCP VPC
```

## Quick Start

### Option 1: Local Development

Run Orbit on your local Kubernetes cluster (minikube, kind, Docker Desktop, or k3s):

```bash
# 1. Build local images
docker build -t orbit-backend:local ./backend
docker build -t orbit-frontend:local ./frontend

# 2. Install the Helm chart with local values
helm install orbit ./infrastructure/helm/orbit -f ./infrastructure/helm/orbit/values-local.yaml

# 3. Add host entry (optional)
echo "127.0.0.1 orbit.local" | sudo tee -a /etc/hosts

# 4. Access the application
# If using minikube: minikube tunnel
# Then open: http://orbit.local
```

### Option 2: Deploy to GKE

```bash
cd infrastructure/terraform/environments/gke

# 1. Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 3. Configure kubectl
$(terraform output -raw kubeconfig_command)

# 4. Check ArgoCD status
kubectl get applications -n argocd
```

### Option 3: Deploy to EKS

```bash
cd infrastructure/terraform/environments/eks

# 1. Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 2. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 3. Configure kubectl
$(terraform output -raw kubeconfig_command)

# 4. Check ArgoCD status
kubectl get applications -n argocd
```

## Architecture

### GitOps Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Git Repo      │───>│    ArgoCD       │───>│   Kubernetes    │
│   (main/dev)    │    │   (watches)     │    │   (deploys)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                v
                       ┌─────────────────┐
                       │ External Secrets│
                       │   Operator      │
                       └────────┬────────┘
                                │
                                v
                       ┌─────────────────┐
                       │ Cloud Secret    │
                       │ Manager (GCP)   │
                       │ Secrets Mgr(AWS)│
                       └─────────────────┘
```

### Terraform Provisions

| Resource | GKE | EKS |
|----------|-----|-----|
| VPC/Network | ✅ VPC, subnets, NAT, firewall | ✅ VPC, subnets, NAT Gateway |
| Kubernetes Cluster | ✅ GKE with node pools | ✅ EKS with managed node groups |
| Database | ✅ Cloud SQL PostgreSQL | ✅ RDS PostgreSQL |
| Secret Management | ✅ GCP Secret Manager | ✅ AWS Secrets Manager |
| Ingress Controller | ✅ nginx-ingress | ✅ nginx-ingress + NLB |
| TLS Certificates | ✅ cert-manager + Let's Encrypt | ✅ cert-manager + Let's Encrypt |
| GitOps | ✅ ArgoCD + External Secrets | ✅ ArgoCD + External Secrets |

### ArgoCD Deploys

- Orbit backend (FastAPI)
- Orbit frontend (React/Nginx)
- Ingress rules
- Horizontal Pod Autoscalers
- Pod Disruption Budgets

## Helm Chart

### Values Hierarchy

For cloud deployments, environment-specific values are embedded in the ArgoCD overlay patches:

1. `values.yaml` - Base defaults (always applied)
2. ArgoCD overlay `values:` block - Environment overrides (production/staging)

For local development:

1. `values.yaml` - Base defaults
2. `values-local.yaml` - Local overrides

### Key Configuration Options

```yaml
# Database options
postgresql:
  enabled: true  # Use built-in PostgreSQL (local/simple deployments)

externalDatabase:
  enabled: false  # Use external database (cloud deployments)
  existingSecret: "orbit-db-credentials"
  # Option 1: Full connection string
  existingSecretConnectionStringKey: "DATABASE_URL"
  # Option 2: Individual components
  # host: ""
  # existingSecretPasswordKey: "password"
```

## Environment Configuration

### Production (ArgoCD Overlay)

- Branch: `main`
- Namespace: `orbit-production`
- Replicas: 2 (with autoscaling)
- Resources: Production-sized limits
- TLS: Enabled with Let's Encrypt production

### Staging (ArgoCD Overlay)

- Branch: `develop`
- Namespace: `orbit-staging`
- Replicas: 1 (no autoscaling)
- Resources: Minimal limits
- TLS: Enabled with Let's Encrypt staging

## Customization

### Changing Image Repository

Update the ArgoCD overlay for your environment:

```yaml
# infrastructure/argocd/overlays/production/application-patch.yaml
spec:
  source:
    helm:
      values: |
        backend:
          image:
            repository: ghcr.io/YOUR_ORG/orbit-backend
        frontend:
          image:
            repository: ghcr.io/YOUR_ORG/orbit-frontend
```

### Adding Custom Environment Variables

Add to the ArgoCD overlay's values block:

```yaml
backend:
  env:
    MY_CUSTOM_VAR: "value"
```

## Troubleshooting

### ArgoCD Sync Issues

```bash
# Check application status
kubectl get applications -n argocd

# View sync details
kubectl describe application orbit -n argocd

# Force sync
argocd app sync orbit
```

### External Secrets Issues

```bash
# Check ExternalSecret status
kubectl get externalsecrets -n orbit

# Describe for errors
kubectl describe externalsecret orbit-db-credentials -n orbit

# Check if secret was created
kubectl get secret orbit-db-credentials -n orbit
```

### Database Connection Issues

```bash
# Verify secret contents
kubectl get secret orbit-db-credentials -n orbit -o yaml

# Check backend logs
kubectl logs -l app.kubernetes.io/component=backend -n orbit

# Test database connectivity from pod
kubectl exec -it deploy/orbit-backend -n orbit -- \
  python -c "import asyncpg; print('DB OK')"
```
