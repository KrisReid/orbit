# Self-Hosting Guide

This guide covers deploying Orbit. Choose local development or cloud deployment based on your needs.

## Table of Contents

- [Local Development](#local-development)
- [Cloud Deployment (EKS/GKE)](#cloud-deployment-eksgke)
- [Troubleshooting](#troubleshooting)

---

## Local Development

### Option 1: Docker Compose (Simplest)

```bash
# Clone the repository
git clone https://github.com/YOUR_ORG/orbit.git
cd orbit

# Copy environment file
cp .env.example .env

# Start all services
docker compose up -d

# Access the application
open http://localhost
```

**Default credentials:**
- Email: `admin@orbit.example.com`
- Password: `admin123`

> ⚠️ Change the default password immediately after first login.

### Option 2: Local Kubernetes (Helm)

For testing Kubernetes deployments locally using minikube, kind, or Docker Desktop:

```bash
# Start local Kubernetes (example with minikube)
minikube start

# Build and load local images
docker build -t orbit-backend:local ./backend
docker build -t orbit-frontend:local ./frontend
minikube image load orbit-backend:local
minikube image load orbit-frontend:local

# Install Helm chart
helm dependency update ./infrastructure/helm/orbit
helm install orbit ./infrastructure/helm/orbit \
  -f ./infrastructure/helm/orbit/values-local.yaml

# Access the application
minikube tunnel  # Run in separate terminal
echo "127.0.0.1 orbit.local" | sudo tee -a /etc/hosts
open http://orbit.local
```

---

## Cloud Deployment (EKS/GKE)

Production deployment using Terraform (infrastructure) and ArgoCD (application).

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- AWS CLI (for EKS) or gcloud CLI (for GKE)
- A domain name for TLS

### Step 1: Fork the Repository

Fork or clone the Orbit repository to your own GitHub organization. You'll need this for ArgoCD to sync from.

### Step 2: Deploy Infrastructure with Terraform

**For AWS EKS:**
```bash
cd infrastructure/terraform/environments/eks

# Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Edit with your values

# Deploy infrastructure
terraform init
terraform apply

# Configure kubectl
aws eks update-kubeconfig \
  --name $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region)
```

**For GCP GKE:**
```bash
cd infrastructure/terraform/environments/gke

# Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Edit with your values

# Deploy infrastructure
terraform init
terraform apply

# Configure kubectl (command from terraform output)
$(terraform output -raw kubeconfig_command)
```

Terraform creates:
- VPC and networking
- Kubernetes cluster (EKS or GKE)
- Managed PostgreSQL database (RDS or Cloud SQL)
- ArgoCD installation
- External Secrets Operator with database credentials

### Step 3: Deploy Application with ArgoCD

```bash
# Edit the overlay with your configuration
vim infrastructure/argocd/overlays/production/application-patch.yaml
```

**Update these values:**
- `source.repoURL`: Your forked Git repository URL
- `ingress.host`: Your production domain
- `image repositories`: Your container registry (e.g., `ghcr.io/YOUR_ORG/orbit-backend`)

```bash
# Apply the ArgoCD Application
kustomize build infrastructure/argocd/overlays/production | kubectl apply -f -

# Check deployment status
kubectl get applications -n argocd
```

### Step 4: Configure DNS

Point your domain to the ingress controller:

```bash
# Get the load balancer address
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Create a DNS A record (or CNAME) pointing your domain to this address.

### Step 5: Access ArgoCD UI (Optional)

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open https://localhost:8080 (username: admin)
```

### GitOps Workflow

After initial deployment, ArgoCD automatically syncs changes:

1. Push changes to your repository (main branch)
2. ArgoCD detects changes and syncs automatically
3. Monitor status: `kubectl get applications -n argocd`

For staging environment, use the staging overlay which tracks the `develop` branch:
```bash
kustomize build infrastructure/argocd/overlays/staging | kubectl apply -f -
```

---

## Troubleshooting

### Application Not Starting

```bash
# Check pod status
kubectl get pods -n orbit

# View pod logs
kubectl logs -l app.kubernetes.io/name=orbit-backend -n orbit
```

### Database Connection Issues

```bash
# Verify secret exists
kubectl get secret orbit-db-credentials -n orbit

# Check ExternalSecret status
kubectl get externalsecrets -n orbit
kubectl describe externalsecret orbit-db-credentials -n orbit
```

### ArgoCD Sync Issues

```bash
# Check application status
kubectl get applications -n argocd
kubectl describe application orbit -n argocd

# Force sync
argocd app sync orbit
```

### TLS Certificate Not Ready

```bash
# Check certificate status
kubectl get certificates -n orbit
kubectl describe certificate orbit-tls -n orbit

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

---

## Additional Resources

- [Architecture Guide](architecture.md) - Technical architecture details
- [Contributing Guide](../CONTRIBUTING.md) - Development workflow
