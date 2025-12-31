# =============================================================================
# GitOps GCP Module
# =============================================================================
# Bootstraps the GitOps pipeline for GKE:
# - ClusterSecretStore pointing to GCP Secret Manager
# - ExternalSecret that syncs database credentials to Kubernetes
# - Application namespace
#
# Note: The GCP Service Account for External Secrets is created in the
# environment module to avoid circular dependencies with kubernetes-addons.
# =============================================================================

locals {
  secret_store_name = "${var.cluster_name}-cluster-secret-store"
}

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

  timeouts {
    delete = "10m"
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}

# -----------------------------------------------------------------------------
# ClusterSecretStore
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "cluster_secret_store" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = local.secret_store_name
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
# ExternalSecret for Database Credentials
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "database_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = var.kubernetes_secret_name
      namespace = var.application_namespace
    }
    spec = {
      refreshInterval = var.secret_refresh_interval
      secretStoreRef = {
        name = local.secret_store_name
        kind = "ClusterSecretStore"
      }
      target = {
        name = var.kubernetes_secret_name
        template = {
          engineVersion = "v2"
          data = {
            DATABASE_URL      = "{{ .connection_string }}"
            DATABASE_HOST     = "{{ .host }}"
            DATABASE_PORT     = "{{ .port }}"
            DATABASE_NAME     = "{{ .database }}"
            DATABASE_USER     = "{{ .username }}"
            DATABASE_PASSWORD = "{{ .password }}"
          }
        }
      }
      dataFrom = [{
        extract = {
          key = var.database_secret_id
        }
      }]
    }
  })

  depends_on = [
    kubectl_manifest.cluster_secret_store,
    kubernetes_namespace_v1.application
  ]
}
