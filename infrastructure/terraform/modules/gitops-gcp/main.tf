# =============================================================================
# GitOps GCP Module
# =============================================================================
# Bootstraps the GitOps pipeline for GKE:
# - ClusterSecretStore pointing to GCP Secret Manager
# - ExternalSecret that syncs database credentials to Kubernetes
# - Application namespace
#
# Note: The ArgoCD Application is NOT created here - it should be applied
# via GitOps using the overlays in infrastructure/argocd/overlays/
#
# Note: The GCP Service Account for External Secrets and Workload Identity
# binding should be created in the calling module to avoid dependency cycles.
# =============================================================================

# -----------------------------------------------------------------------------
# Application Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "application" {
  metadata {
    name = var.application_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "orbit"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

# -----------------------------------------------------------------------------
# ClusterSecretStore - Points to GCP Secret Manager
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "secret_store" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "gcp-secret-manager"
    }
    spec = {
      provider = {
        gcpsm = {
          projectID = var.project_id
          auth = {
            workloadIdentity = {
              clusterLocation  = var.cluster_location
              clusterName      = var.cluster_name
              clusterProjectID = var.project_id
              serviceAccountRef = {
                name      = var.external_secrets_service_account
                namespace = var.external_secrets_namespace
              }
            }
          }
        }
      }
    }
  })

  depends_on = [var.external_secrets_ready]
}

# -----------------------------------------------------------------------------
# ExternalSecret - Syncs database password from Secret Manager
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "database_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "orbit-db-credentials"
      namespace = var.application_namespace
    }
    spec = {
      refreshInterval = var.secret_refresh_interval
      secretStoreRef = {
        name = "gcp-secret-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "orbit-db-credentials"
        template = {
          type = "Opaque"
          data = {
            # Full connection string for the backend
            DATABASE_URL = "postgresql+asyncpg://${var.database_user}:{{ .db_password }}@${var.database_host}:5432/${var.database_name}"
            # Individual components if needed
            DB_HOST     = var.database_host
            DB_PORT     = "5432"
            DB_NAME     = var.database_name
            DB_USER     = var.database_user
            DB_PASSWORD = "{{ .db_password }}"
          }
        }
      }
      data = [
        {
          secretKey = "db_password"
          remoteRef = {
            key     = var.database_secret_id
            version = "latest"
          }
        }
      ]
    }
  })

  depends_on = [kubectl_manifest.secret_store, kubernetes_namespace_v1.application]
}
