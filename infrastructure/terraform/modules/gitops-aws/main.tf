# =============================================================================
# GitOps AWS Module
# =============================================================================
# Sets up the GitOps pipeline for EKS:
# - SecretStore pointing to AWS Secrets Manager
# - ExternalSecret that syncs database credentials
# - ArgoCD Application that deploys Orbit
#
# Prerequisites:
# - External Secrets Operator installed in cluster
# - IAM role for External Secrets with Secrets Manager access (via IRSA)
# =============================================================================

# -----------------------------------------------------------------------------
# IAM Role for External Secrets (IRSA)
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "external_secrets" {
  count = var.create_irsa_role ? 1 : 0
  name  = "${var.cluster_name}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_service_account}"
            "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "external_secrets" {
  count = var.create_irsa_role ? 1 : 0
  name  = "secrets-manager-access"
  role  = aws_iam_role.external_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = var.allowed_secret_arns != null ? var.allowed_secret_arns : ["arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:*"]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# SecretStore - Points to AWS Secrets Manager
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "secret_store" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets-manager"
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
# ExternalSecret - Syncs database password from Secrets Manager
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
        name = "aws-secrets-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name = "orbit-db-credentials"
        template = {
          type = "Opaque"
          data = {
            # Full connection string for the backend
            DATABASE_URL = "postgresql://${var.database_user}:{{ .password }}@${var.database_host}:5432/${var.database_name}"
            # Individual components if needed
            DB_HOST     = var.database_host
            DB_PORT     = "5432"
            DB_NAME     = var.database_name
            DB_USER     = var.database_user
            DB_PASSWORD = "{{ .password }}"
          }
        }
      }
      data = [
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

  depends_on = [kubectl_manifest.secret_store, kubernetes_namespace_v1.application]
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
      name       = "orbit"
      namespace  = var.argocd_namespace
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
            }
            frontend = {
              image = {
                repository = var.frontend_image_repository
                tag        = var.frontend_image_tag
              }
            }
            ingress = {
              enabled   = var.enable_ingress
              className = "nginx"
              annotations = {
                "cert-manager.io/cluster-issuer" = var.cluster_issuer
              }
              host = var.ingress_host
              tls = {
                enabled    = var.enable_tls
                secretName = "orbit-tls"
              }
            }
            # Disable built-in PostgreSQL since we use RDS
            postgresql = {
              enabled = false
            }
            # Use external database with connection string from External Secrets
            externalDatabase = {
              enabled                          = true
              existingSecret                   = "orbit-db-credentials"
              existingSecretConnectionStringKey = "DATABASE_URL"
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
        automated = null
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
resource "kubernetes_namespace_v1" "application" {
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
