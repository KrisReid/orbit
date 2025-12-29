# Infrastructure

Infrastructure-as-code for deploying Orbit to Kubernetes.

> **📖 For deployment instructions, see [Self-Hosting Guide](../docs/SELF-HOSTING.md)**

## Directory Structure

```
infrastructure/
├── argocd/                    # ArgoCD Application definitions
│   ├── base/                  # Base manifest
│   └── overlays/              # Environment patches (production, staging)
├── helm/orbit/                # Helm chart
│   ├── values.yaml            # Default values
│   └── values-local.yaml      # Local development values
└── terraform/
    ├── environments/          # Root modules
    │   ├── eks/               # AWS EKS
    │   └── gke/               # GCP GKE
    └── modules/               # Reusable modules
        ├── database-aws/      # RDS PostgreSQL
        ├── database-gcp/      # Cloud SQL
        ├── eks/               # EKS cluster
        ├── gke/               # GKE cluster
        ├── gitops-aws/        # SecretStore + ExternalSecret (AWS)
        ├── gitops-gcp/        # SecretStore + ExternalSecret (GCP)
        ├── kubernetes-addons/ # nginx, cert-manager, ArgoCD, ESO
        ├── vpc-aws/           # AWS VPC
        └── vpc-gcp/           # GCP VPC
```

## Architecture

```
Terraform                          ArgoCD
┌──────────────────────────┐      ┌──────────────────────────┐
│ • VPC / Networking       │      │ • Watches Git repo       │
│ • Kubernetes Cluster     │      │ • Deploys Helm chart     │
│ • Managed Database       │  ──▶ │ • Auto-syncs changes     │
│ • ArgoCD + ESO           │      │                          │
│ • ClusterSecretStore     │      │                          │
│ • ExternalSecret         │      │                          │
└──────────────────────────┘      └──────────────────────────┘
     Infrastructure                    Application
```

## Quick Reference

### Helm Values

| Value | Description | Default |
|-------|-------------|---------|
| `postgresql.enabled` | Use built-in PostgreSQL | `true` |
| `externalDatabase.enabled` | Use external database | `false` |
| `externalDatabase.existingSecret` | Secret with DATABASE_URL | `""` |
| `ingress.host` | Application hostname | `orbit.example.com` |
| `backend.autoscaling.enabled` | Enable HPA | `false` |

### Terraform Variables

See `terraform.tfvars.example` in each environment. Key variables:

| Variable | Description |
|----------|-------------|
| `project_name` | Resource name prefix |
| `region` | Cloud region |
| `enable_gitops_bootstrap` | Create SecretStore + ExternalSecret |
| `letsencrypt_email` | Email for Let's Encrypt |

### ArgoCD Overlays

| Overlay | Branch | Namespace | Use |
|---------|--------|-----------|-----|
| `production` | main | orbit | Production deployment |
| `staging` | develop | orbit-staging | Staging/testing |
