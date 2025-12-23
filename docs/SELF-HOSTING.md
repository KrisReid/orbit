# Self-Hosting Guide

This guide covers deploying Orbit for your organization. Choose the deployment method that best fits your infrastructure.

## Table of Contents

- [Quick Start](#quick-start)
- [Deployment Options](#deployment-options)
- [Docker Compose Deployment](#docker-compose-deployment)
- [Kubernetes Deployment (Helm)](#kubernetes-deployment-helm)
- [GitOps Deployment (ArgoCD)](#gitops-deployment-argocd)
- [Configuration Reference](#configuration-reference)
- [TLS/HTTPS Setup](#tlshttps-setup)
- [Database Management](#database-management)
- [Backup and Restore](#backup-and-restore)
- [Upgrading](#upgrading)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

The fastest way to get Orbit running:

```bash
# Clone the repository
git clone https://github.com/your-org/orbit.git
cd orbit

# Run the installation script
./install.sh

# Start Orbit
docker compose -f docker-compose.prod.yml up -d
```

Access Orbit at `https://your-domain.com` (or `http://localhost` for local testing).

**Default credentials:**
- Email: `admin@orbit.example.com`
- Password: `admin123`

> ⚠️ **Change the default password immediately after first login!!!**

---

## Deployment Options

| Method | Best For | Complexity | High Availability |
|--------|----------|------------|-------------------|
| [Docker Compose](#docker-compose-deployment) | Small teams, single server | Low | No |
| [Kubernetes (Helm)](#kubernetes-deployment) | Medium to large orgs | Medium | Yes |
| [GitOps (ArgoCD)](#gitops-deployment) | Enterprise, platform teams | High | Yes |

---

## Docker Compose Deployment

### Prerequisites

- **Operating System:** Linux (Ubuntu 20.04+, Debian 11+, RHEL 8+), macOS, or Windows with WSL2
- **Docker:** 20.10+ with Docker Compose v2
- **Memory:** Minimum 2GB RAM (4GB+ recommended)
- **Storage:** Minimum 10GB free disk space
- **Network:** Port 80 and 443 available (or custom ports)

### Installation Steps

#### 1. Clone the Repository

```bash
git clone https://github.com/your-org/orbit.git
cd orbit
```

#### 2. Run the Installation Script

```bash
./install.sh
```

The script will:
- Check Docker prerequisites
- Generate secure secrets (SECRET_KEY, POSTGRES_PASSWORD)
- Create `.env` configuration file
- Guide you through domain and email configuration

#### 3. Configure Your Domain (Production)

For production deployments, ensure:

1. **DNS is configured:** Your domain points to the server's IP address
2. **Ports are open:** 80 (HTTP) and 443 (HTTPS) are accessible
3. **Email is valid:** Required for Let's Encrypt certificates

Edit `.env` if needed:

```bash
DOMAIN=orbit.yourcompany.com
ACME_EMAIL=admin@yourcompany.com
```

#### 4. Start Orbit

**Local testing (HTTP only):**
```bash
docker compose -f docker-compose.prod.yml up -d
```

**Production (with TLS):**
```bash
docker compose -f docker-compose.prod.yml -f docker-compose.tls.yml up -d
```

#### 5. Verify Deployment

```bash
# Check all containers are running
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f

# Test health endpoint
curl http://localhost/health
```

### Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Docker Host                              │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Traefik                           │   │
│  │              (Reverse Proxy + TLS)                   │   │
│  │                                                      │   │
│  │    :80 ──► HTTP redirect to HTTPS                   │   │
│  │    :443 ──► Routes to services                      │   │
│  └──────────────────────┬──────────────────────────────┘   │
│                         │                                   │
│         ┌───────────────┴───────────────┐                  │
│         │                               │                  │
│         ▼                               ▼                  │
│  ┌─────────────┐                ┌─────────────┐           │
│  │  Frontend   │                │   Backend   │           │
│  │   (nginx)   │                │  (FastAPI)  │           │
│  │             │                │             │           │
│  │ Static SPA  │                │  REST API   │           │
│  └─────────────┘                └──────┬──────┘           │
│                                        │                   │
│                                        ▼                   │
│                                 ┌─────────────┐           │
│                                 │ PostgreSQL  │           │
│                                 │             │           │
│                                 │ [Volume]    │           │
│                                 └─────────────┘           │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

---

## Kubernetes Deployment (Helm)

For production deployments requiring high availability, scalability, and enterprise features.

### Prerequisites

- **Kubernetes:** 1.25+ (EKS, GKE, AKS, or self-managed)
- **Helm:** 3.10+
- **kubectl:** Configured with cluster access
- **Ingress Controller:** nginx-ingress or Traefik
- **cert-manager:** (Optional) For automatic TLS

### Quick Start

```bash
# Clone the repository
git clone https://github.com/your-org/orbit.git
cd orbit

# Add Bitnami repo for PostgreSQL dependency
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Update Helm dependencies
helm dependency update helm/orbit

# Install Orbit
helm install orbit helm/orbit \
  --namespace orbit \
  --create-namespace \
  --set ingress.host=orbit.yourcompany.com \
  --set postgresql.auth.password=your-secure-password \
  --set backend.secrets.secretKey=your-secret-key
```

### Custom Values File

Create a `my-values.yaml` for your environment:

```yaml
# my-values.yaml
backend:
  replicaCount: 2
  image:
    repository: ghcr.io/your-org/orbit-backend
    tag: "1.0.0"
  resources:
    requests:
      memory: "512Mi"
      cpu: "250m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10

frontend:
  replicaCount: 2
  image:
    repository: ghcr.io/your-org/orbit-frontend
    tag: "1.0.0"

ingress:
  enabled: true
  className: nginx
  host: orbit.yourcompany.com
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  tls:
    enabled: true
    secretName: orbit-tls

postgresql:
  enabled: true
  auth:
    password: "your-secure-db-password"
  primary:
    persistence:
      size: 20Gi
```

Install with custom values:

```bash
helm install orbit helm/orbit \
  --namespace orbit \
  --create-namespace \
  -f my-values.yaml
```

### Using External Database

To use an existing PostgreSQL (RDS, CloudSQL, etc.):

```yaml
# my-values.yaml
postgresql:
  enabled: false

externalDatabase:
  enabled: true
  host: your-db-host.rds.amazonaws.com
  port: 5432
  database: orbit
  username: orbit
  existingSecret: orbit-db-credentials
  existingSecretPasswordKey: password
```

Create the database secret:

```bash
kubectl create secret generic orbit-db-credentials \
  --namespace orbit \
  --from-literal=password=your-db-password
```

### Upgrading

```bash
# Update to new version
helm upgrade orbit helm/orbit \
  --namespace orbit \
  -f my-values.yaml \
  --set backend.image.tag=1.1.0 \
  --set frontend.image.tag=1.1.0
```

### Rollback

```bash
# List revision history
helm history orbit --namespace orbit

# Rollback to previous revision
helm rollback orbit --namespace orbit

# Rollback to specific revision
helm rollback orbit 2 --namespace orbit
```

### Uninstall

```bash
# Uninstall Orbit (keeps PVCs by default)
helm uninstall orbit --namespace orbit

# Delete namespace and all resources
kubectl delete namespace orbit
```

---

## GitOps Deployment (ArgoCD)

For enterprise teams using GitOps workflows with ArgoCD.

### Prerequisites

- **Kubernetes:** 1.25+
- **ArgoCD:** 2.8+ installed on the cluster
- **Git repository:** Fork of Orbit or your own repo

### Setup ArgoCD Application

#### Option 1: Apply directly

```bash
# Apply the ArgoCD Application
kubectl apply -f argocd/base/application.yaml
```

#### Option 2: Using Kustomize overlays

For environment-specific deployments:

```bash
# Production
kustomize build argocd/overlays/production | kubectl apply -f -

# Staging
kustomize build argocd/overlays/staging | kubectl apply -f -
```

### Configure Values

Edit the values files for your environment:

**Production (`argocd/values/production.yaml`):**
```yaml
ingress:
  host: orbit.yourcompany.com  # <-- Change this

postgresql:
  auth:
    existingSecret: orbit-db-credentials  # <-- Create this secret
```

**Staging (`argocd/values/staging.yaml`):**
```yaml
ingress:
  host: staging.orbit.yourcompany.com  # <-- Change this
```

### Secrets Management

ArgoCD doesn't sync secrets by default. Use one of these approaches:

**Option A: External Secrets Operator**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: orbit-secrets
  namespace: orbit
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: orbit-backend
  data:
    - secretKey: SECRET_KEY
      remoteRef:
        key: orbit/production
        property: secret_key
```

**Option B: Sealed Secrets**
```bash
# Seal your secret
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# Add to git repository
git add sealed-secret.yaml
git commit -m "Add sealed secrets"
git push
```

**Option C: Manual Secret Creation**
```bash
kubectl create secret generic orbit-backend \
  --namespace orbit \
  --from-literal=SECRET_KEY=$(openssl rand -base64 32)
```

### GitOps Workflow

1. **Make changes** to values files in git
2. **Commit and push** to your repository
3. **ArgoCD detects changes** and syncs automatically (if auto-sync enabled)
4. **Monitor sync status** in ArgoCD UI or CLI

```bash
# Check application status
argocd app get orbit

# Sync manually if needed
argocd app sync orbit

# View sync history
argocd app history orbit
```

### Multi-Environment Setup

```
argocd/
├── base/
│   ├── application.yaml      # Base ArgoCD Application
│   └── kustomization.yaml
├── overlays/
│   ├── production/
│   │   ├── application-patch.yaml
│   │   └── kustomization.yaml
│   └── staging/
│       ├── application-patch.yaml
│       └── kustomization.yaml
└── values/
    ├── common.yaml           # Shared values
    ├── production.yaml       # Production overrides
    └── staging.yaml          # Staging overrides
```

---

## Configuration Reference

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `DOMAIN` | Domain where Orbit is accessible | `localhost` | Yes |
| `ACME_EMAIL` | Email for Let's Encrypt certificates | - | For TLS |
| `SECRET_KEY` | JWT signing key (auto-generated) | - | Yes |
| `POSTGRES_PASSWORD` | Database password (auto-generated) | - | Yes |
| `POSTGRES_USER` | Database username | `orbit` | No |
| `POSTGRES_DB` | Database name | `orbit` | No |
| `TASK_ID_PREFIX` | Prefix for task IDs (e.g., MYORG-123) | `ORBIT` | No |
| `DEBUG` | Enable debug mode | `false` | No |

### GitHub Integration (Optional)

| Variable | Description |
|----------|-------------|
| `GITHUB_WEBHOOK_SECRET` | Secret for GitHub webhooks |
| `GITHUB_APP_ID` | GitHub App ID for advanced integration |
| `GITHUB_PRIVATE_KEY` | GitHub App private key |

---

## TLS/HTTPS Setup

### Automatic (Let's Encrypt)

The default `docker-compose.prod.yml` automatically handles TLS via Traefik and Let's Encrypt:

1. Ensure your domain's DNS points to the server
2. Port 80 must be accessible (for ACME challenge)
3. Set `ACME_EMAIL` in `.env`
4. Start the stack - certificates are automatically obtained

### Custom Certificates

To use your own certificates:

1. Place certificates in a `certs/` directory:
   ```
   certs/
   ├── cert.pem
   └── key.pem
   ```

2. Update Traefik configuration in `docker-compose.prod.yml`:
   ```yaml
   traefik:
     volumes:
       - ./certs:/certs:ro
     command:
       # ... existing commands ...
       - "--providers.file.filename=/etc/traefik/dynamic.yml"
   ```

3. Create `traefik-dynamic.yml`:
   ```yaml
   tls:
     certificates:
       - certFile: /certs/cert.pem
         keyFile: /certs/key.pem
   ```

### Behind a Load Balancer

If Orbit is behind an AWS ALB, Cloudflare, or similar:

1. Use `docker-compose.prod.yml` without the TLS overlay (HTTP only)
2. Configure your load balancer to handle TLS termination
3. Set appropriate headers for forwarded requests

---

## Database Management

### Accessing PostgreSQL

```bash
# Connect to the database container
docker compose -f docker-compose.prod.yml exec db psql -U orbit -d orbit

# Run SQL commands
\dt          # List tables
\d users     # Describe users table
SELECT * FROM users LIMIT 5;
```

### Database Migrations

Migrations run automatically on startup. To manually trigger:

```bash
docker compose -f docker-compose.prod.yml exec backend python -m alembic upgrade head
```

### Using External Database

To use an external PostgreSQL (RDS, CloudSQL, etc.):

1. Comment out the `db` service in `docker-compose.prod.yml`
2. Update `DATABASE_URL` in `.env`:
   ```
   DATABASE_URL=postgresql+asyncpg://user:password@your-db-host:5432/orbit
   ```

---

## Backup and Restore

### Database Backup

**Manual backup:**
```bash
# Create backup
docker compose -f docker-compose.prod.yml exec db pg_dump -U orbit orbit > backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
docker compose -f docker-compose.prod.yml exec db pg_dump -U orbit -Fc orbit > backup_$(date +%Y%m%d_%H%M%S).dump
```

**Automated backups (cron):**
```bash
# Add to crontab (daily at 2 AM)
0 2 * * * cd /path/to/orbit && docker compose -f docker-compose.prod.yml exec -T db pg_dump -U orbit -Fc orbit > /backups/orbit_$(date +\%Y\%m\%d).dump
```

### Database Restore

```bash
# From SQL file
docker compose -f docker-compose.prod.yml exec -T db psql -U orbit -d orbit < backup.sql

# From compressed dump
docker compose -f docker-compose.prod.yml exec -T db pg_restore -U orbit -d orbit < backup.dump
```

### Full System Backup

```bash
# Stop services
docker compose -f docker-compose.prod.yml down

# Backup volumes
docker run --rm -v orbit_postgres-data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_data.tar.gz /data

# Backup configuration
cp .env .env.backup

# Restart services
docker compose -f docker-compose.prod.yml up -d
```

---

## Upgrading

### Standard Upgrade

```bash
# Pull latest code
git pull origin main

# Pull latest images
docker compose -f docker-compose.prod.yml pull

# Restart with new images
docker compose -f docker-compose.prod.yml up -d

# Verify
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f backend
```

### Upgrading to Specific Version

```bash
# Checkout specific version
git fetch --tags
git checkout v1.2.3

# Update and restart
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

### Rollback

```bash
# Checkout previous version
git checkout v1.2.2

# Restore previous images
docker compose -f docker-compose.prod.yml up -d

# If database migration issues, restore from backup
docker compose -f docker-compose.prod.yml exec -T db psql -U orbit -d orbit < backup.sql
```

---

## Troubleshooting

### Common Issues

#### Container won't start

```bash
# Check container status
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs backend
docker compose -f docker-compose.prod.yml logs db
```

#### Database connection errors

```bash
# Verify database is healthy
docker compose -f docker-compose.prod.yml exec db pg_isready -U orbit

# Check database logs
docker compose -f docker-compose.prod.yml logs db
```

#### TLS certificate issues

```bash
# Check Traefik logs
docker compose -f docker-compose.prod.yml logs traefik

# Verify ACME challenge is accessible
curl http://your-domain.com/.well-known/acme-challenge/test
```

#### Port already in use

```bash
# Find process using port
sudo lsof -i :80
sudo lsof -i :443

# Kill process or change port in docker-compose
```

### Health Checks

```bash
# Backend health
curl http://localhost:8000/health

# Frontend health
curl http://localhost/health

# Full stack (through Traefik)
curl https://your-domain.com/health
curl https://your-domain.com/api/v1/health
```

### Reset Everything

```bash
# Stop all containers
docker compose -f docker-compose.prod.yml down

# Remove volumes (DELETES ALL DATA!)
docker compose -f docker-compose.prod.yml down -v

# Remove images
docker compose -f docker-compose.prod.yml down --rmi all

# Fresh start
./install.sh
docker compose -f docker-compose.prod.yml up -d
```

---

## Security Checklist

Before deploying to production:

- [ ] Changed default admin password
- [ ] Set unique `SECRET_KEY` (auto-generated by install script)
- [ ] Set unique `POSTGRES_PASSWORD` (auto-generated by install script)
- [ ] Configured valid domain and TLS
- [ ] Set `DEBUG=false`
- [ ] Configured firewall (only ports 80, 443 exposed)
- [ ] Set up automated backups
- [ ] Reviewed CORS settings
- [ ] Configured log rotation

---

## Getting Help

- **Documentation:** [docs/architecture.md](architecture.md)
- **Issues:** [GitHub Issues](https://github.com/your-org/orbit/issues)
- **Discussions:** [GitHub Discussions](https://github.com/your-org/orbit/discussions)
