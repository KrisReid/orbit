# Self-Hosting Guide

Deploy Orbit locally or to a cloud Kubernetes cluster.

## Deployment Options

| Option | Complexity | Best For |
|--------|------------|----------|
| [Docker Compose](#docker-compose) | Simple | Local development, demos |
| [Local Kubernetes](#local-kubernetes) | Medium | Testing K8s before production |
| [Cloud (EKS/GKE)](#cloud-deployment) | Advanced | Production deployments |

---

## Docker Compose

The quickest way to run Orbit locally.

```bash
git clone https://github.com/YOUR_ORG/orbit.git
cd orbit
cp .env.example .env
docker compose up -d
```

**Access:** http://localhost  
**Login:** `admin@orbit.example.com` / `admin123`

> ⚠️ Change the default password after first login.

---

## Local Kubernetes

Test Kubernetes deployments using minikube, kind, or Docker Desktop.

```bash
# Start local cluster
minikube start

# Build and load images
docker build -t orbit-backend:local ./backend
docker build -t orbit-frontend:local ./frontend
minikube image load orbit-backend:local orbit-frontend:local

# Install with Helm
helm dependency update ./infrastructure/helm/orbit
helm install orbit ./infrastructure/helm/orbit -f ./infrastructure/helm/orbit/values-local.yaml

# Access
minikube tunnel  # Run in separate terminal
echo "127.0.0.1 orbit.local" | sudo tee -a /etc/hosts
```

**Access:** http://orbit.local

---

## Cloud Deployment

Production deployment to AWS EKS or GCP GKE using Terraform and ArgoCD.

### Prerequisites

- Terraform >= 1.5.0
- kubectl
- AWS CLI or gcloud CLI
- A domain name for TLS

### Step 1: Deploy Infrastructure

```bash
cd infrastructure/terraform/environments/production

# Configure for your cloud provider
cp terraform.tfvars.gcp.example terraform.tfvars  # or .aws.example
vim terraform.tfvars

# Deploy
terraform init
terraform apply

# Configure kubectl
$(terraform output -raw kubeconfig_command)
```

**What Terraform creates:**
- VPC and networking
- Kubernetes cluster (EKS or GKE)
- Managed PostgreSQL (RDS or Cloud SQL)
- ArgoCD with External Secrets Operator

### Step 2: Configure CI/CD (Optional)

To enable GitHub Actions CI/CD with Workload Identity Federation, first enable it in your `terraform.tfvars`:

```hcl
# Add to your terraform.tfvars
enable_github_actions_cicd = true
github_repository          = "your-org/orbit"  # Format: owner/repo
```

Then re-apply Terraform and get the outputs:

```bash
terraform apply

# Get GitHub Actions secrets
terraform output github_actions_workload_identity_provider
terraform output github_actions_service_account
```

Add these values to your GitHub repository Settings → Secrets and variables → Actions.

### Step 3: Deploy Application

```bash
# Return to project root
cd ../../../..

# Edit overlay with your settings (repo URL, domain, registry)
vim infrastructure/argocd/overlays/production/application-patch.yaml

# Apply ArgoCD application
kustomize build infrastructure/argocd/overlays/production | kubectl apply -f -
```

### Step 4: Configure DNS

Point your domain to the ingress load balancer:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## Troubleshooting

### Pods Not Starting

```bash
kubectl get pods -n orbit
kubectl logs -l app.kubernetes.io/name=orbit-backend -n orbit
```

### Database Connection Issues

```bash
kubectl get externalsecrets -n orbit
kubectl describe externalsecret orbit-db-credentials -n orbit
```

### ArgoCD Sync Issues

```bash
kubectl get applications -n argocd
kubectl describe application orbit -n argocd
```

### TLS Certificate Issues

```bash
kubectl get certificates -n orbit
kubectl logs -n cert-manager -l app=cert-manager
```

---

## Related Documentation

- [Architecture Guide](architecture.md) — Technical details
- [Infrastructure README](../infrastructure/README.md) — IaC options
- [Contributing Guide](../CONTRIBUTING.md) — Development setup
