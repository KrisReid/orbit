# Orbit GitOps Setup with ArgoCD

This guide walks through setting up the Orbit project management system on a Kubernetes cluster using a GitOps workflow with Terraform and ArgoCD.

## Architecture Overview

The deployment uses a fully automated GitOps pipeline:

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Terraform     │────▶│  GCP Secret      │────▶│ External Secrets│
│   (Cloud SQL)   │     │  Manager         │     │ Operator        │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Git Repo      │────▶│    ArgoCD        │────▶│  Orbit App      │
│   (Helm Chart)  │     │                  │     │  (K8s)          │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

**Key Features:**
- **Single source of truth** - Database password stored in GCP Secret Manager
- **Automatic secret sync** - External Secrets Operator syncs to Kubernetes
- **Zero manual steps** - After `terraform apply`, everything is automated
- **Full audit trail** - All secrets access logged in GCP

## 1. Prerequisites

Ensure you have the following tools installed:

- `terraform` >= 1.0
- `kubectl`
- `gcloud` CLI (authenticated with your project)

Optional but recommended:
- `kubectx` / `kubens`

## 2. Quick Start (GKE)

### Step 1: Configure Your Variables

```bash
cd infrastructure/terraform/environments/gke

# Copy the example file
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
# Required settings
project_id   = "your-gcp-project-id"
project_name = "orbit"
region       = "us-central1"

# Your Git repository (fork or clone of orbit)
git_repo_url = "https://github.com/YOUR_ORG/orbit.git"

# Your domain
ingress_host      = "orbit.example.com"
letsencrypt_email = "admin@example.com"

# Your container registry
backend_image_repository  = "ghcr.io/YOUR_ORG/orbit-backend"
frontend_image_repository = "ghcr.io/YOUR_ORG/orbit-frontend"
```

### Step 2: Deploy Everything

```bash
terraform init
terraform apply
```

That's it! Terraform will:

1. ✅ Enable required GCP APIs
2. ✅ Create VPC and networking
3. ✅ Provision GKE cluster
4. ✅ Create Cloud SQL database (password auto-stored in Secret Manager)
5. ✅ Install NGINX Ingress Controller
6. ✅ Install cert-manager with Let's Encrypt issuers
7. ✅ Install ArgoCD
8. ✅ Install External Secrets Operator with Workload Identity
9. ✅ Create SecretStore pointing to GCP Secret Manager
10. ✅ Create ExternalSecret that syncs database credentials
11. ✅ Deploy ArgoCD Application for Orbit

### Step 3: Access Your Deployment

After terraform completes, run:

```bash
# Configure kubectl
$(terraform output -raw kubeconfig_command)

# View next steps
terraform output next_steps
```

## 3. How It Works

### Secret Flow

1. **Terraform** creates Cloud SQL and generates a password
2. **Password** is stored in GCP Secret Manager
3. **External Secrets Operator** (running in K8s) uses Workload Identity to authenticate to GCP
4. **ExternalSecret** resource tells ESO which secret to fetch and how to format it
5. **Kubernetes Secret** (`orbit-db-credentials`) is automatically created/updated
6. **Orbit backend** mounts this secret and uses the `DATABASE_URL` environment variable

### GitOps Flow

1. **ArgoCD Application** points to your Git repository's Helm chart
2. When you push changes to `main`, ArgoCD detects them
3. ArgoCD syncs the changes to the cluster
4. Application is updated with zero manual intervention

## 4. Configuration Details

### Required Terraform Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_id` | GCP project ID | `my-project-123` |
| `project_name` | Name prefix for resources | `orbit` |
| `region` | GCP region | `us-central1` |
| `git_repo_url` | Your Git repository URL | `https://github.com/org/orbit.git` |
| `ingress_host` | Domain for the application | `orbit.example.com` |
| `letsencrypt_email` | Email for Let's Encrypt | `admin@example.com` |

### Optional Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_gitops_bootstrap` | `true` | Enable automated GitOps setup |
| `enable_auto_sync` | `true` | Enable ArgoCD auto-sync |
| `cluster_issuer` | `letsencrypt-prod` | cert-manager issuer |
| `secret_refresh_interval` | `1h` | How often to sync secrets |

## 5. Accessing Services

### ArgoCD UI

```bash
# Get the ArgoCD LoadBalancer IP
kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Or port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080 (user: admin)
```

### Application

Once DNS is configured and Let's Encrypt has issued a certificate:
- Frontend: `https://orbit.example.com`
- Backend API: `https://orbit.example.com/api`

## 6. Verify Deployment

### Check All Components

```bash
# External Secrets Operator
kubectl get pods -n external-secrets

# SecretStore status
kubectl get clustersecretstore gcp-secret-manager

# ExternalSecret status (should show "SecretSynced")
kubectl get externalsecret -n orbit orbit-db-credentials

# Kubernetes secret (created by ESO)
kubectl get secret -n orbit orbit-db-credentials

# ArgoCD Application
kubectl get application -n argocd orbit

# Application pods
kubectl get pods -n orbit
```

### Expected Output

```
# External Secrets should show SecretSynced
NAME                   STORE                REFRESH INTERVAL   STATUS
orbit-db-credentials   gcp-secret-manager   1h                 SecretSynced

# ArgoCD Application should show Synced and Healthy
NAME    SYNC STATUS   HEALTH STATUS
orbit   Synced        Healthy
```

## 7. Daily Operations

### Deployments

1. Push changes to your `main` branch
2. GitHub Actions builds and pushes container images
3. ArgoCD detects the change and syncs automatically

### Manual Sync (if auto-sync disabled)

```bash
# Via CLI
argocd app sync orbit

# Or via UI
# Click "Sync" button in ArgoCD UI
```

### Rollbacks

```bash
# Via ArgoCD CLI
argocd app rollback orbit

# Or revert the Git commit
git revert HEAD
git push
```

### View Logs

```bash
kubectl logs -n orbit -l app.kubernetes.io/name=orbit-backend -f
kubectl logs -n orbit -l app.kubernetes.io/name=orbit-frontend -f
```

### Secret Rotation

To rotate the database password:

1. Update the secret in GCP Secret Manager
2. External Secrets Operator will sync the new value within the refresh interval (default: 1h)
3. Restart the backend pods to pick up the new secret:
   ```bash
   kubectl rollout restart deployment -n orbit orbit-backend
   ```

## 8. Troubleshooting

### ExternalSecret Not Syncing

```bash
# Check ESO logs
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets

# Check ExternalSecret status
kubectl describe externalsecret -n orbit orbit-db-credentials
```

Common issues:
- **Workload Identity not configured**: Check the service account annotation
- **Secret not found in GCP**: Verify the secret exists in Secret Manager
- **Permission denied**: Check the GCP service account has `secretmanager.secretAccessor` role

### ArgoCD Sync Failures

```bash
# Check application status
argocd app get orbit

# View sync details
kubectl describe application -n argocd orbit
```

Common issues:
- **Repository not accessible**: Check `git_repo_url` is correct and public (or configure SSH key)
- **Helm chart errors**: Check the Helm values in the ArgoCD Application

### Database Connection Issues

```bash
# Verify the secret exists and has correct data
kubectl get secret -n orbit orbit-db-credentials -o yaml

# Check the backend logs
kubectl logs -n orbit -l app.kubernetes.io/name=orbit-backend

# Test database connectivity from a debug pod
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql "postgresql://orbit:PASSWORD@DB_IP:5432/orbit"
```

### ImagePullBackOff

Check that:
1. Container images exist in the registry
2. Image tags are correct in `terraform.tfvars`
3. Registry is publicly accessible (or configure image pull secrets)

## 9. Cleanup

To destroy all infrastructure:

```bash
# First, disable deletion protection in terraform.tfvars
deletion_protection = false

# Then destroy
terraform destroy
```

**Warning**: This will delete all data including the Cloud SQL database.

## 10. Advanced Topics

### Using a Private Git Repository

For private repositories, configure ArgoCD with SSH keys or a deploy token:

```bash
# Add repository credentials to ArgoCD
argocd repo add https://github.com/org/orbit.git --username git --password <token>
```

### Custom Secret Refresh Interval

To sync secrets more frequently:

```hcl
secret_refresh_interval = "15m"  # Check every 15 minutes
```

### Disabling Auto-Sync

For manual deployment control:

```hcl
enable_auto_sync = false
```

Then sync manually via ArgoCD UI or CLI.

### Multiple Environments

Create separate terraform workspaces or directories for staging/production:

```bash
# Using workspaces
terraform workspace new staging
terraform workspace new production

# Or separate directories
infrastructure/terraform/environments/gke-staging/
infrastructure/terraform/environments/gke-production/
```

## Migration from Manual Setup

If you previously set up Orbit with manual secrets:

1. Delete the old manual secret:
   ```bash
   kubectl delete secret -n orbit orbit-db-secret
   ```

2. Enable External Secrets in `terraform.tfvars`:
   ```hcl
   enable_external_secrets  = true
   enable_gitops_bootstrap = true
   ```

3. Apply Terraform:
   ```bash
   terraform apply
   ```

4. The ExternalSecret will create a new `orbit-db-credentials` secret automatically.
