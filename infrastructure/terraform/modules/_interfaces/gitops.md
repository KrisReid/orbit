# GitOps Module Interface Contract

This document defines the required interface that all GitOps bootstrap module implementations must satisfy.

## Purpose

Bootstrap the GitOps pipeline by:
1. Creating the application namespace
2. Configuring External Secrets Operator to access cloud secrets
3. Creating ExternalSecret to sync database credentials

## Required Input Variables

All implementations MUST accept these variables:

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `cluster_name` | string | yes | Kubernetes cluster name |
| `region` | string | yes | Cloud region |
| `application_namespace` | string | no | Namespace to create (default: "orbit") |
| `external_secrets_namespace` | string | no | ESO namespace (default: "external-secrets") |
| `external_secrets_service_account` | string | no | ESO service account name |
| `secret_refresh_interval` | string | no | How often to sync secrets (default: "1h") |
| `database_host` | string | yes | Database hostname |
| `database_name` | string | yes | Database name |
| `database_user` | string | yes | Database username |
| `database_secret_id` | string | yes | Cloud secret ID containing DB credentials |
| `kubernetes_secret_name` | string | no | K8s secret name to create (default: "orbit-database") |
| `tags` | map(string) | no | Resource tags/labels |

### AWS-Specific Variables

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `oidc_provider_arn` | string | yes | EKS OIDC provider ARN |
| `oidc_provider_url` | string | yes | EKS OIDC provider URL |

### GCP-Specific Variables

| Variable | Type | Required | Description |
|----------|------|----------|-------------|
| `project_id` | string | yes | GCP project ID |
| `cluster_location` | string | yes | Cluster location (region or zone) |

## Required Outputs

All implementations MUST provide these outputs:

| Output | Type | Description |
|--------|------|-------------|
| `application_namespace` | string | Created namespace name |
| `kubernetes_secret_name` | string | Name of K8s secret with DB credentials |
| `cluster_secret_store_name` | string | Name of ClusterSecretStore |

### AWS-Specific Outputs

| Output | Type | Description |
|--------|------|-------------|
| `external_secrets_role_arn` | string | IAM role ARN for ESO |

### GCP-Specific Outputs

| Output | Type | Description |
|--------|------|-------------|
| `external_secrets_service_account_email` | string | GCP SA email for ESO |

## Created Resources

### Kubernetes Resources (Both Providers)

1. **Namespace**
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: orbit
   ```

2. **ClusterSecretStore**
   ```yaml
   apiVersion: external-secrets.io/v1beta1
   kind: ClusterSecretStore
   metadata:
     name: orbit-cluster-secret-store
   spec:
     provider:
       # AWS or GCP specific configuration
   ```

3. **ExternalSecret**
   ```yaml
   apiVersion: external-secrets.io/v1beta1
   kind: ExternalSecret
   metadata:
     name: orbit-database
     namespace: orbit
   spec:
     refreshInterval: 1h
     secretStoreRef:
       name: orbit-cluster-secret-store
       kind: ClusterSecretStore
     target:
       name: orbit-database
     data:
       - secretKey: DATABASE_URL
         remoteRef:
           key: orbit-db-credentials
           property: connection_string
   ```

### AWS-Specific Resources

- IAM Role for External Secrets (IRSA)
- IAM Policy for Secrets Manager access

### GCP-Specific Resources

- Service Account for External Secrets
- Workload Identity binding
- IAM binding for Secret Manager access

## Secret Structure

The ExternalSecret creates a Kubernetes secret with:

| Key | Source | Description |
|-----|--------|-------------|
| `DATABASE_URL` | connection_string | Full PostgreSQL URI |
| `DATABASE_HOST` | host | Database hostname |
| `DATABASE_PORT` | port | Database port |
| `DATABASE_NAME` | database | Database name |
| `DATABASE_USER` | username | Database username |
| `DATABASE_PASSWORD` | password | Database password |

## CrossPlane Compatibility

Example XRD claim:
```yaml
apiVersion: orbit.io/v1alpha1
kind: GitOpsBootstrap
metadata:
  name: orbit-gitops
spec:
  parameters:
    applicationNamespace: orbit
    databaseSecretId: orbit-db-credentials
    secretRefreshInterval: 1h
```

## Dependencies

This module requires:
- Kubernetes cluster is running
- External Secrets Operator is installed (via kubernetes-addons)
- Database module has created the cloud secret
