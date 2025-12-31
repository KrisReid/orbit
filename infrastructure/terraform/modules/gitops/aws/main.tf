# =============================================================================
# GitOps AWS Module
# =============================================================================
# Bootstraps the GitOps pipeline for EKS:
# - ClusterSecretStore pointing to AWS Secrets Manager
# - ExternalSecret that syncs database credentials to Kubernetes
# - Application namespace
#
# Note: The IAM Role for External Secrets is created in the environment
# module to avoid circular dependencies with kubernetes-addons.
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
        aws = {
          service = "SecretsManager"
          region  = var.region
          auth = {
            jwt = {
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
      data = [
        {
          secretKey = "connection_string"
          remoteRef = {
            key      = var.database_secret_name
            property = "connection_string"
          }
        },
        {
          secretKey = "host"
          remoteRef = {
            key      = var.database_secret_name
            property = "host"
          }
        },
        {
          secretKey = "port"
          remoteRef = {
            key      = var.database_secret_name
            property = "port"
          }
        },
        {
          secretKey = "database"
          remoteRef = {
            key      = var.database_secret_name
            property = "database"
          }
        },
        {
          secretKey = "username"
          remoteRef = {
            key      = var.database_secret_name
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = var.database_secret_name
            property = "password"
          }
        }
      ]
    }
  })

  depends_on = [
    kubectl_manifest.cluster_secret_store,
    kubernetes_namespace_v1.application
  ]
}
