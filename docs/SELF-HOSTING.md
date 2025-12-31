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
- Docker (for building images)
- AWS CLI or gcloud CLI (authenticated)
- A domain name for TLS (optional but recommended)

### Step 1: Deploy Infrastructure

Terraform creates all required infrastructure including the container registry.

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
- **Container Registry** (Artifact Registry or ECR)
- NGINX Ingress Controller
- cert-manager with Let's Encrypt
- ArgoCD
- External Secrets Operator
- **ArgoCD Application** (automatically deploys Orbit)

### Step 2: Configure CI/CD for Automatic Deployments

The CI/CD pipeline automatically builds and pushes container images when you push to `main`. You need to configure GitHub secrets first.

**1. Get credentials from Terraform:**
```bash
terraform output github_actions_workload_identity_provider
terraform output github_actions_service_account
terraform output container_registry
```

**2. Configure GitHub Repository:**

Go to your repository: **Settings → Secrets and variables → Actions**

**For GCP - Add Secrets:**
| Secret Name | Value |
|-------------|-------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Output from terraform |
| `GCP_SERVICE_ACCOUNT` | Output from terraform |

**For GCP - Add Variables:**
| Variable Name | Value |
|---------------|-------|
| `CLOUD_PROVIDER` | `gcp` |
| `GCP_PROJECT_ID` | Your GCP project ID |
| `GCP_REGION` | Your region (e.g., `europe-west2`) |
| `GAR_REPOSITORY` | `orbit` |

**For AWS - Add Secrets:**
| Secret Name | Value |
|-------------|-------|
| `AWS_ROLE_ARN` | Output from terraform |
| `AWS_ACCOUNT_ID` | Your AWS account ID |

**For AWS - Add Variables:**
| Variable Name | Value |
|---------------|-------|
| `CLOUD_PROVIDER` | `aws` |
| `AWS_REGION` | Your region (e.g., `us-east-1`) |
| `ECR_REPOSITORY` | `orbit` |

**3. Trigger the pipeline:**
```bash
git commit --allow-empty -m "trigger: initial deployment"
git push origin main
```

The pipeline will build both images and push them to your registry. ArgoCD will then automatically deploy them.

> **Note:** For the initial deployment only, if you prefer to build manually without CI/CD, see [Manual Image Build](#manual-image-build) below.

### Step 3: Access Your Deployment

After `terraform apply` completes:

```bash
# Configure kubectl
$(terraform output -raw kubeconfig_command)
```

#### Access ArgoCD UI

ArgoCD provides a web interface to monitor your application deployments.

**1. Start port forwarding** (run this in a terminal and keep it running):
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

**2. Get the admin password** (run in a separate terminal):
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

**3. Open ArgoCD:**
- URL: http://localhost:8080
- **Username:** `admin`
- **Password:** (output from command above)

> **Tip:** The port forwarding must remain active to access the ArgoCD UI. If you close the terminal, you'll need to run the port-forward command again.

#### Access the Application

**1. Get your load balancer IP:**
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' && echo
```

**2. Add the IP to your hosts file:**

Replace `<LOAD_BALANCER_IP>` with the IP from step 1, and use the domain you configured in `application_domain` (default: `orbit.example.com`):

```bash
# macOS/Linux
sudo sh -c 'echo "<LOAD_BALANCER_IP> orbit.example.com" >> /etc/hosts'

# Windows (run PowerShell as Administrator)
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "<LOAD_BALANCER_IP> orbit.example.com"
```

**Example:** If your load balancer IP is `34.39.54.70`:
```bash
sudo sh -c 'echo "34.39.54.70 orbit.example.com" >> /etc/hosts'
```

**3. Access the application:**
- URL: http://orbit.example.com (or https:// if you configured TLS)
- **Default login:** `admin@orbit.example.com` / `admin123`

> ⚠️ **Important:** Change the default password after first login!

**Alternative: Configure Real DNS**

For production use, instead of editing `/etc/hosts`, configure your domain's DNS:
1. Go to your DNS provider (e.g., Cloudflare, Route53, Cloud DNS)
2. Create an A record pointing your domain to the load balancer IP
3. Wait for DNS propagation (usually 5-15 minutes)

---

## Manual Image Build

If you prefer to build and push images manually instead of using CI/CD:

```bash
# Get registry URL from Terraform
terraform output container_registry
terraform output container_registry_auth_command
```

**GCP Artifact Registry:**
```bash
# Set variables
REGION="europe-west2"
PROJECT_ID="your-project-id"

# Authenticate
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Build and push
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/orbit/backend:latest ./backend
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/orbit/frontend:latest ./frontend
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/orbit/backend:latest
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/orbit/frontend:latest
```

**AWS ECR:**
```bash
# Set variables
REGION="us-east-1"
ACCOUNT_ID="123456789012"

# Authenticate
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build and push
docker build -t ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/orbit/backend:latest ./backend
docker build -t ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/orbit/frontend:latest ./frontend
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/orbit/backend:latest
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/orbit/frontend:latest
```

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
