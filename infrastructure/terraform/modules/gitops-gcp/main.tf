# =============================================================================
# GitOps GCP Module
# =============================================================================
# Sets up the GitOps pipeline for GKE:
# - SecretStore pointing to GCP Secret Manager
# - ExternalSecret that syncs database credentials
# - ArgoCD Application that deploys Orbit
#
# Note: The GCP Service Account for External Secrets and Workload Identity
# binding should be created in the calling module to avoid dependency cycles.
# =============================================================================

# -----------------------------------------------------------------------------
# SecretStore - Points to GCP Secret Manager
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
            DATABASE_URL = "postgresql://${var.database_user}:{{ .db_password }}@${var.database_host}:5432/${var.database_name}"
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

  depends_on = [kubectl_manifest.secret_store, kubernetes_namespace.application]
}

# -----------------------------------------------------------------------------
# ArgoCD Application - Deploys Orbit via Helm
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "argocd_application" {
  count = var.deploy_argocd_application ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "orbit"
      namespace = var.argocd_namespace
      finalizers = var.enable_argocd_finalizer ? ["resources-finalizer.argocd.argoproj.io"] : []
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = var.git_target_revision
        path           = var.helm_chart_path
        helm = {
          valueFiles = var.helm_value_files
          values = yamlencode({
            # Override values that need to come from Terraform
            backend = {
              image = {
                repository = var.backend_image_repository
                tag        = var.backend_image_tag
              }
              existingSecret = "orbit-db-credentials"
              secretKeys = {
                databaseUrl = "DATABASE_URL"
              }
            }
            frontend = {
              image = {
                repository = var.frontend_image_repository
                tag        = var.frontend_image_tag
              }
            }
            ingress = {
              enabled = var.enable_ingress
              className = "nginx"
              annotations = {
                "cert-manager.io/cluster-issuer" = var.cluster_issuer
              }
              hosts = [
                {
                  host = var.ingress_host
                  paths = [
                    {
                      path     = "/api"
                      pathType = "Prefix"
                      service  = "backend"
                    },
                    {
                      path     = "/"
                      pathType = "Prefix"
                      service  = "frontend"
                    }
                  ]
                }
              ]
              tls = var.enable_tls ? [
                {
                  secretName = "orbit-tls"
                  hosts      = [var.ingress_host]
                }
              ] : []
            }
            # Disable built-in PostgreSQL since we use Cloud SQL
            postgresql = {
              enabled = false
            }
          })
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.application_namespace
      }
      syncPolicy = var.enable_auto_sync ? {
        automated = {
          prune    = var.auto_sync_prune
          selfHeal = var.auto_sync_self_heal
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      } : {
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  })

  depends_on = [kubectl_manifest.database_external_secret]
}

# -----------------------------------------------------------------------------
# Create application namespace if it doesn't exist
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "application" {
  metadata {
    name = var.application_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      metadata[0].labels,
    ]
  }
}
