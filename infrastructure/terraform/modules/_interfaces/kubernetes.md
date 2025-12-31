# Kubernetes Module Interface Contract

This document defines the required output interface that all Kubernetes cluster implementations must satisfy.

## Purpose

While EKS and GKE have significantly different configurations and are kept as separate modules, they must provide consistent outputs for downstream consumers (kubernetes-addons, gitops, helm providers).

## Note on Abstraction

Unlike Network and Database modules, Kubernetes is NOT abstracted into a platform module because:

1. Configuration differences are substantial (IRSA vs Workload Identity, node groups vs node pools)
2. Clusters are foundational infrastructure, provisioned once
3. CrossPlane typically runs ON the cluster, not used to provision it
4. The environment module handles provider selection

## Required Outputs

All implementations MUST provide these outputs:

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `cluster_name` | string | no | Cluster name |
| `cluster_endpoint` | string | yes | API server endpoint URL |
| `cluster_ca_certificate` | string | yes | Base64-encoded CA certificate |
| `kubeconfig_command` | string | no | CLI command to configure kubectl |

### Authentication Outputs

| Output | Type | Description |
|--------|------|-------------|
| `cluster_auth_token` | string | Auth token (GCP) or null (AWS uses exec) |

### Workload Identity Outputs

| Output | Type | Description |
|--------|------|-------------|
| `workload_identity_pool` | string | Workload identity pool (GCP) |
| `oidc_provider_arn` | string | OIDC provider ARN (AWS) |
| `oidc_provider_url` | string | OIDC provider URL (AWS) |

### Node/Security Outputs

| Output | Type | Description |
|--------|------|-------------|
| `node_security_group_id` | string | Node security group ID (AWS) |
| `cluster_security_group_id` | string | Cluster security group ID (AWS) |

## Provider Configuration

The outputs must enable configuring Kubernetes/Helm providers:

### AWS (EKS)
```hcl
provider "kubernetes" {
  host                   = module.kubernetes.cluster_endpoint
  cluster_ca_certificate = module.kubernetes.cluster_ca_certificate
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.kubernetes.cluster_name]
  }
}
```

### GCP (GKE)
```hcl
provider "kubernetes" {
  host                   = "https://${module.kubernetes.cluster_endpoint}"
  cluster_ca_certificate = module.kubernetes.cluster_ca_certificate
  token                  = data.google_client_config.default.access_token
}
```

## Implementation Requirements

### AWS (EKS)
- Create EKS cluster with managed node groups
- Configure OIDC provider for IRSA
- Enable required addons (VPC CNI, CoreDNS, kube-proxy, EBS CSI)
- Create cluster and node security groups
- Configure CloudWatch logging

### GCP (GKE)
- Create GKE cluster (regional or zonal)
- Configure Workload Identity
- Enable required addons (HTTP LB, HPA, Network Policy)
- Configure private cluster settings
- Set up Cloud Logging/Monitoring

## Node Configuration

Each implementation accepts cloud-specific node pool/group configuration:

### AWS Node Groups
```hcl
node_groups = {
  default = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    desired_size   = 2
    min_size       = 1
    max_size       = 4
  }
}
```

### GCP Node Pools
```hcl
node_pools = {
  default = {
    machine_type       = "e2-medium"
    initial_node_count = 1
    min_node_count     = 1
    max_node_count     = 3
    preemptible        = false
  }
}
```

## CrossPlane Note

Kubernetes clusters are typically NOT managed by CrossPlane because:
- CrossPlane runs on the cluster (chicken-and-egg)
- Cluster lifecycle is different from day-2 resources
- Terraform/Pulumi better suited for cluster provisioning

CrossPlane is ideal for day-2 resources:
- Databases
- Storage buckets
- IAM roles
- DNS records
