# Network Module Interface Contract

This document defines the required interface that all network module implementations must satisfy.

## Purpose

Enable cloud-agnostic VPC/network provisioning while maintaining consistent outputs for downstream consumers (Kubernetes clusters, databases, load balancers).

## Required Input Variables

All implementations MUST accept these variables:

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | yes | Resource name prefix |
| `region` | string | yes | Cloud region for deployment |
| `vpc_cidr` | string | no | Primary CIDR block (default: "10.0.0.0/16") |
| `availability_zone_count` | number | no | Number of AZs to use (default: 3) |
| `enable_nat` | bool | no | Enable NAT for private subnets (default: true) |
| `single_nat` | bool | no | Use single NAT vs one per AZ (default: false) |
| `enable_private_subnets` | bool | no | Create private subnets (default: true) |
| `enable_database_subnets` | bool | no | Create database subnet group (default: true) |
| `kubernetes_cluster_name` | string | no | Cluster name for subnet tagging |
| `tags` | map(string) | no | Resource tags/labels |

### GCP-Specific Variables

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `gcp_project_id` | string | yes (GCP) | GCP project ID |
| `pods_cidr` | string | no | Secondary range for K8s pods |
| `services_cidr` | string | no | Secondary range for K8s services |
| `enable_private_google_access` | bool | no | Enable private Google access |

## Required Outputs

All implementations MUST provide these outputs:

| Output | Type | Description |
|--------|------|-------------|
| `vpc_id` | string | VPC/Network ID |
| `vpc_cidr` | string | VPC primary CIDR block |
| `public_subnet_ids` | list(string) | Public subnet IDs |
| `private_subnet_ids` | list(string) | Private subnet IDs |
| `database_subnet_ids` | list(string) | Database subnet IDs (if enabled) |
| `database_subnet_group_name` | string | DB subnet group name (AWS) |
| `nat_gateway_ips` | list(string) | NAT Gateway public IPs |
| `availability_zones` | list(string) | AZs used |

### GCP-Specific Outputs

| Output | Type | Description |
|--------|------|-------------|
| `vpc_self_link` | string | Full VPC resource path |
| `subnet_self_link` | string | Subnet self link |
| `pods_range_name` | string | Secondary range name for pods |
| `services_range_name` | string | Secondary range name for services |
| `private_services_connection` | string | Private services connection ID |

### AWS-Specific Outputs

| Output | Type | Description |
|--------|------|-------------|
| `vpc_id` | string | VPC ID |
| `db_subnet_group_name` | string | RDS subnet group name |
| `db_subnet_group_arn` | string | RDS subnet group ARN |

## Subnet Strategy

### AWS
- Public subnets: One per AZ, auto-assign public IPs
- Private subnets: One per AZ, route through NAT
- Database subnets: Private, in DB subnet group

### GCP
- Single regional subnet with:
  - Primary range for nodes
  - Secondary range for pods
  - Secondary range for services
- Private Google Access enabled
- Cloud NAT for egress

## Kubernetes Tagging

Subnets must be tagged for Kubernetes cloud provider integration:

### AWS
```hcl
"kubernetes.io/cluster/${cluster_name}" = "shared"
"kubernetes.io/role/elb"                = "1"      # Public subnets
"kubernetes.io/role/internal-elb"       = "1"      # Private subnets
```

### GCP
Labels applied at subnet level; GKE uses VPC-native networking with secondary ranges.

## CrossPlane Compatibility

The XRD should accept the same normalized inputs and provide consistent outputs.

Example claim:
```yaml
apiVersion: orbit.io/v1alpha1
kind: Network
metadata:
  name: orbit-network
spec:
  parameters:
    region: us-east-1
    vpcCidr: "10.0.0.0/16"
    availabilityZoneCount: 3
    enableNat: true
    kubernetesClusterName: orbit-cluster
```
