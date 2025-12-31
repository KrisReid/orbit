# Database Module Interface Contract

This document defines the required interface that all database module implementations must satisfy.

## Purpose

Enable cloud-agnostic database provisioning while maintaining consistent outputs for downstream consumers (Helm charts, External Secrets, application configuration).

## Required Input Variables

All implementations MUST accept these variables:

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `name` | string | yes | Resource name/identifier |
| `region` | string | yes | Cloud region for deployment |
| `engine_version` | string | no | PostgreSQL version (default: "15") |
| `instance_size` | string | no | Normalized size: "small", "medium", "large", "xlarge" |
| `storage_gb` | number | no | Initial storage allocation (default: 20) |
| `storage_autoscaling` | bool | no | Enable automatic storage scaling (default: true) |
| `max_storage_gb` | number | no | Maximum storage for autoscaling (default: 100) |
| `high_availability` | bool | no | Enable multi-AZ/regional deployment (default: false) |
| `backup_retention_days` | number | no | Backup retention period (default: 7) |
| `database_name` | string | no | Initial database name (default: "app") |
| `database_user` | string | no | Master username (default: "app") |
| `password` | string | no | Master password (generated if null) |
| `allowed_security_groups` | list(string) | no | Security groups allowed to connect (AWS) |
| `allowed_cidr_blocks` | list(string) | no | CIDR blocks allowed to connect |
| `create_secret` | bool | no | Create cloud secret with credentials (default: true) |
| `deletion_protection` | bool | no | Prevent accidental deletion (default: true) |
| `skip_final_snapshot` | bool | no | Skip final snapshot on deletion (default: false) |
| `tags` | map(string) | no | Resource tags/labels |

### AWS-Specific Variables

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `vpc_id` | string | yes | VPC ID for security group |
| `db_subnet_group_name` | string | yes | DB subnet group name |
| `performance_insights_enabled` | bool | no | Enable Performance Insights |
| `monitoring_interval` | number | no | Enhanced monitoring interval |

### GCP-Specific Variables

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `project_id` | string | yes | GCP project ID |
| `private_network` | string | yes | VPC self_link for private IP |
| `insights_enabled` | bool | no | Enable Query Insights |

## Required Outputs

All implementations MUST provide these outputs:

| Output | Type | Sensitive | Description |
|--------|------|-----------|-------------|
| `instance_id` | string | no | Cloud-specific instance identifier |
| `host` | string | no | Database hostname/IP for connections |
| `port` | number | no | Database port (typically 5432) |
| `database_name` | string | no | Name of the created database |
| `database_user` | string | no | Master username |
| `database_password` | string | yes | Master password |
| `connection_string` | string | yes | Full PostgreSQL connection URI |
| `secret_id` | string | no | Cloud secret ID containing credentials |

### AWS-Specific Outputs

| Output | Type | Description |
|--------|------|-------------|
| `instance_arn` | string | RDS instance ARN |
| `instance_endpoint` | string | Full endpoint (host:port) |
| `security_group_id` | string | RDS security group ID |
| `secret_arn` | string | Secrets Manager secret ARN |

### GCP-Specific Outputs

| Output | Type | Description |
|--------|------|-------------|
| `instance_connection_name` | string | Cloud SQL connection name (for proxy) |
| `instance_self_link` | string | Instance self_link |

## Instance Size Mapping

Implementations map normalized sizes to cloud-specific instance types:

| Normalized | AWS | GCP |
|------------|-----|-----|
| small | db.t3.micro | db-f1-micro |
| medium | db.t3.small | db-g1-small |
| large | db.r6g.large | db-custom-2-7680 |
| xlarge | db.r6g.xlarge | db-custom-4-15360 |

## Secret Structure

The cloud secret should contain a JSON object with:

```json
{
  "username": "app",
  "password": "generated-password",
  "host": "10.0.1.5",
  "port": 5432,
  "database": "orbit",
  "connection_string": "postgresql://app:password@10.0.1.5:5432/orbit"
}
```

## CrossPlane Compatibility

Example XRD claim:
```yaml
apiVersion: orbit.io/v1alpha1
kind: Database
metadata:
  name: orbit-db
spec:
  parameters:
    region: us-east-1
    instanceSize: medium
    storageGb: 50
    highAvailability: true
    databaseName: orbit
```
