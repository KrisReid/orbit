# Orbit Terraform Infrastructure

This directory contains Terraform configurations for deploying Orbit to either Google Kubernetes Engine (GKE) or Amazon Elastic Kubernetes Service (EKS).

## Architecture Overview

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── gke/                    # GKE cluster module
│   ├── eks/                    # EKS cluster module
│   ├── vpc-gcp/                # GCP VPC networking
│   ├── vpc-aws/                # AWS VPC networking
│   ├── database-gcp/           # Cloud SQL PostgreSQL
│   ├── database-aws/           # RDS PostgreSQL
│   ├── kubernetes-addons/      # NGINX Ingress, cert-manager
│   └── orbit/                  # Orbit Helm release
├── environments/
│   ├── gke/                    # GKE deployment configuration
│   └── eks/                    # EKS deployment configuration
```

## Prerequisites

### Common Requirements
- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) >= 3.0

### For GKE
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- A GCP project with billing enabled
- Enabled APIs: Kubernetes Engine, Cloud SQL, Compute Engine

### For EKS
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- An AWS account with appropriate permissions
- AWS credentials configured

## Quick Start

### Deploying to GKE

```bash
cd terraform/environments/gke

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### Deploying to EKS

```bash
cd terraform/environments/eks

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

## Configuration

### Required Variables

| Variable | Description | GKE | EKS |
|----------|-------------|-----|-----|
| `project_name` | Name prefix for all resources | ✓ | ✓ |
| `environment` | Environment name (e.g., production, staging) | ✓ | ✓ |
| `project_id` | GCP project ID | ✓ | - |
| `region` | Cloud region | ✓ | ✓ |

### Optional Variables

See the `variables.tf` file in each environment directory for all available options.

## Remote State Configuration

For team collaboration, configure remote state storage:

### GKE (Google Cloud Storage)

Create a file named `backend.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "orbit/gke"
  }
}
```

### EKS (Amazon S3)

Create a file named `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "orbit/eks/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

## Post-Deployment

After successful deployment, Terraform will output:

- Kubernetes cluster connection details
- Ingress controller IP/hostname
- Database connection information (for debugging)

### Connect to the Cluster

**GKE:**
```bash
gcloud container clusters get-credentials $(terraform output -raw cluster_name) \
  --region $(terraform output -raw region) \
  --project $(terraform output -raw project_id)
```

**EKS:**
```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw region)
```

### Access the Application

```bash
# Get the ingress IP/hostname
kubectl get ingress -n orbit

# Or from Terraform output
terraform output ingress_hostname
```

## Destroying Infrastructure

```bash
# Review what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy
```

> ⚠️ **Warning**: This will destroy the database and all data. Make sure to backup any important data first.

## Customization

### Using Custom Values for Orbit Helm Chart

You can override Helm values by setting the `orbit_helm_values` variable:

```hcl
orbit_helm_values = {
  "backend.replicaCount"           = "3"
  "backend.autoscaling.enabled"    = "true"
  "frontend.autoscaling.enabled"   = "true"
  "ingress.host"                   = "orbit.yourdomain.com"
  "ingress.tls.enabled"            = "true"
}
```

### Bring Your Own VPC

If you have an existing VPC, you can skip VPC creation:

```hcl
create_vpc = false
vpc_id     = "your-existing-vpc-id"
subnet_ids = ["subnet-1", "subnet-2"]
```

## Troubleshooting

### Common Issues

1. **API not enabled** (GKE): Enable required APIs in the GCP Console or via:
   ```bash
   gcloud services enable container.googleapis.com sqladmin.googleapis.com compute.googleapis.com
   ```

2. **Insufficient permissions** (EKS): Ensure your IAM user/role has the required permissions for EKS, VPC, and RDS.

3. **Cluster not ready**: Wait a few minutes after cluster creation for all components to be ready.

### Getting Help

- Check the [Orbit documentation](../docs/SELF-HOSTING.md)
- Open an issue on GitHub
- Review Terraform logs with `TF_LOG=DEBUG terraform apply`

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on contributing to this project.
