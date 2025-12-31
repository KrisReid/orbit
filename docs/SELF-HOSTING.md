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
- Helm (for local testing)
- AWS CLI or gcloud CLI (authenticated)
- A domain name for TLS (optional but recommended)
- Container images pushed to a registry (GCR, ECR, or Artifact Registry)

### Step 1: Prepare Container Images

Before deploying, build and push your container images:

**GCP Artifact Registry:**
```bash
# Authenticate
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Create repository (if not exists)
gcloud artifacts repositories create orbit --repository-format=docker --location=${REGION}

# Build and push
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/orbit/backend:latest ./backend
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/orbit/frontend:latest ./frontend
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/orbit/backend:latest
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/orbit/frontend:latest
```

**AWS ECR:**
```bash
# Authenticate
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Create repositories
aws ecr create-repository --repository-name orbit/backend
aws ecr create-repository --repository-name orbit/frontend

# Build and push
docker build -t ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/orbit/backend:latest ./backend
docker build -t ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/orbit/frontend:latest ./frontend
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/orbit/backend:latest
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/orbit/frontend:latest
```

### Step 2: Deploy Infrastructure

```bash
cd infrastructure/terraform/environments/production

# Configure for your cloud provider
cp terraform.tfvars.gcp.example terraform.tfvars  # or .aws.example

# Edit terraform.tfvars with your values (see Configuration Reference below)
vim terraform.tfvars

# Initialize and deploy
terraform init
terraform apply
```

**What Terraform creates:**
- VPC and networking
- Kubernetes cluster (EKS or GKE)
- Managed PostgreSQL (RDS or Cloud SQL)
- NGINX Ingress Controller
- cert-manager with Let's Encrypt
- ArgoCD
- External Secrets Operator
- **ArgoCD Application** (automatically deploys Orbit)

### Step 3: Access Your Deployment

After `terraform apply` completes:

```bash
# Configure kubectl
$(terraform output -raw kubeconfig_command)

# View next steps
terraform output next_steps
```

#### Access ArgoCD UI

```bash
# Port forward to ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Open http://localhost:8080 and login with:
- **Username:** `admin`
- **Password:** (output from command above)

#### Access the Application

```bash
# Get load balancer IP
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Then either:
1. **Configure DNS:** Point your domain to the load balancer IP
2. **Test locally:** Add to `/etc/hosts`: `<LOAD_BALANCER_IP> orbit.yourdomain.com`

### Step 4: Configure CI/CD (Optional)

To enable GitHub Actions CI/CD with Workload Identity Federation:

```hcl
# Add to your terraform.tfvars
enable_github_actions_cicd = true
github_repository          = "your-org/orbit"  # Format: owner/repo
```

Then re-apply and get the outputs:

```bash
terraform apply

# Get GitHub Actions secrets
terraform output github_actions_workload_identity_provider
terraform output github_actions_service_account
```

Add these values to your GitHub repository: **Settings → Secrets and variables → Actions**

---

## Configuration Reference

### Required Settings

| Variable | Description | Example |
|----------|-------------|---------|
| `cloud_provider` | `aws` or `gcp` | `"gcp"` |
| `region` | Cloud region | `"europe-west2"` |
| `gcp_config.project_id` | GCP project ID (GCP only) | `"my-project"` |

### Application Deployment

| Variable | Description | Default |
|----------|-------------|---------|
| `deploy_argocd_application` | Auto-deploy via ArgoCD | `true` |
| `git_repository_url` | Your forked repo URL | `""` |
| `git_target_revision` | Branch/tag to deploy | `"main"` |
| `application_domain` | Domain for ingress | `""` |
| `container_registry` | Override registry URL | Auto-detected |
| `image_tag` | Container image tag | `"latest"` |

### GitHub Actions CI/CD

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_github_actions_cicd` | Enable Workload Identity | `false` |
| `github_repository` | `owner/repo` format | `""` |

### Database

| Variable | Description | Default |
|----------|-------------|---------|
| `database_instance_size` | `small`, `medium`, `large`, `xlarge` | `"small"` |
| `database_high_availability` | Enable HA | `false` |
| `database_deletion_protection` | Prevent deletion | `true` |

---

## Troubleshooting

### Pods Stuck in Pending

This usually means the cluster needs to scale:
```bash
kubectl describe pod -n orbit <pod-name>
kubectl get nodes
```
Wait 2-5 minutes for autoscaler to add nodes.

### Database Connection Issues

```bash
kubectl get externalsecrets -n orbit
kubectl describe externalsecret orbit-database -n orbit
kubectl get secret orbit-database -n orbit -o yaml
```

### ArgoCD Sync Issues

```bash
kubectl get applications -n argocd
kubectl describe application orbit -n argocd
argocd app sync orbit  # Force sync (requires argocd CLI)
```

### TLS Certificate Issues

```bash
kubectl get certificates -n orbit
kubectl describe certificate orbit-tls -n orbit
kubectl logs -n cert-manager -l app=cert-manager
```

### Helm Chart Errors

If ArgoCD shows Helm errors:
```bash
# Check what ArgoCD sees
kubectl get application orbit -n argocd -o yaml

# Debug locally
helm template orbit ./infrastructure/helm/orbit -f ./infrastructure/helm/orbit/values.yaml
```

### Cannot Access Load Balancer

```bash
# Check service status
kubectl get svc -n ingress-nginx

# Check cloud load balancer (GCP)
gcloud compute forwarding-rules list

# Check cloud load balancer (AWS)
aws elbv2 describe-load-balancers
```

---

## Cleanup

To destroy all resources:

```bash
# First, disable deletion protection (if enabled)
# Edit terraform.tfvars:
#   database_deletion_protection = false
#   cluster_deletion_protection = false
terraform apply

# Then destroy
terraform destroy
```

---

## Related Documentation

- [Infrastructure README](../infrastructure/README.md) — IaC options and architecture
- [Helm Chart Values](../infrastructure/helm/orbit/values.yaml) — All configurable options
- [Contributing Guide](../CONTRIBUTING.md) — Development setup
