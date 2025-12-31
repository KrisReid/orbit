# Terraform Infrastructure

Terraform modules for deploying Orbit to AWS or GCP.

## Directory Structure

```
terraform/
├── environments/
│   ├── production/      # Production configuration
│   └── staging/         # Staging configuration (placeholder)
└── modules/
    ├── _interfaces/     # Interface contract documentation
    ├── platform/        # Cloud-agnostic facades
    ├── network/         # VPC implementations (aws/, gcp/)
    ├── database/        # Database implementations (aws/, gcp/)
    ├── kubernetes/      # Cluster implementations (aws/, gcp/)
    ├── gitops/          # GitOps bootstrap (aws/, gcp/)
    └── kubernetes-addons/
```

## Usage

```bash
cd environments/production

# Copy the example for your cloud provider
cp terraform.tfvars.gcp.example terraform.tfvars  # or .aws.example

# Edit with your settings
vim terraform.tfvars

# Deploy
terraform init
terraform plan
terraform apply

# Configure kubectl
$(terraform output -raw kubeconfig_command)
```

## Configuration

Key variables in `terraform.tfvars`:

```hcl
cloud_provider = "gcp"  # or "aws"
project_name   = "orbit"
environment    = "production"
region         = "europe-west2"  # or "us-east-1" for AWS

# Provider-specific config
gcp_config = {
  project_id       = "your-gcp-project-id"
  regional_cluster = true
}
```

## Module Interfaces

Platform modules use consistent interfaces across cloud providers. See [`_interfaces/`](_interfaces/) for specifications.

**Common pattern:**

| Input | Description |
|-------|-------------|
| `cloud_provider` | `aws` or `gcp` |
| `instance_size` | `small`, `medium`, `large`, `xlarge` |
| `high_availability` | Enable multi-AZ/regional |

**Instance size mapping:**

| Size | AWS | GCP |
|------|-----|-----|
| small | db.t3.micro | db-f1-micro |
| medium | db.t3.small | db-g1-small |
| large | db.r6g.large | db-custom-2-7680 |
| xlarge | db.r6g.xlarge | db-custom-4-15360 |

## Troubleshooting

**Authentication:**
```bash
# AWS
aws sts get-caller-identity

# GCP
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

**State issues:**
```bash
terraform refresh
terraform import module.network.aws[0].aws_vpc.main vpc-12345
```
