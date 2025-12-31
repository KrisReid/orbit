# Infrastructure

Cloud-agnostic Infrastructure-as-Code for deploying Orbit to AWS or GCP.

## What's Here

```
infrastructure/
├── terraform/     # Terraform modules and environments
├── crossplane/    # CrossPlane XRDs for K8s-native IaC
├── helm/          # Helm chart for application deployment
└── argocd/        # ArgoCD application manifests
```

## Getting Started

**Choose your approach:**

| Approach | Best For | Documentation |
|----------|----------|---------------|
| Terraform | Traditional IaC, most teams | [terraform/README.md](terraform/README.md) |
| CrossPlane | K8s-native, GitOps-first teams | [crossplane/README.md](crossplane/README.md) |

Both approaches deploy identical infrastructure:
- VPC with private subnets and NAT
- Kubernetes cluster (EKS or GKE)
- Managed PostgreSQL (RDS or Cloud SQL)
- GitOps tooling (ArgoCD, External Secrets Operator)

## Quick Start (Terraform)

```bash
cd terraform/environments/production
cp terraform.tfvars.gcp.example terraform.tfvars  # or .aws.example
# Edit terraform.tfvars with your settings

terraform init
terraform apply
```

## Cloud Provider Selection

Set `cloud_provider = "gcp"` or `cloud_provider = "aws"` in your configuration. All modules automatically use the correct provider-specific implementation.

## Related Documentation

- [Self-Hosting Guide](../docs/SELF-HOSTING.md) — End-to-end deployment walkthrough
- [Interface Contracts](terraform/modules/_interfaces/) — Module interface specifications
