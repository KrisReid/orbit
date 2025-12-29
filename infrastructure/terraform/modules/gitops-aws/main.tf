# =============================================================================
# GitOps AWS Module
# =============================================================================
# Bootstraps the GitOps pipeline for EKS:
# - IAM Role for External Secrets (IRSA)
# - ClusterSecretStore pointing to AWS Secrets Manager
# - ExternalSecret that syncs database credentials to Kubernetes
# - Application namespace
#
# Note: The ArgoCD Application is NOT created here - it should be applied
# via GitOps using the overlays in infrastructure/argocd/overlays/
#
# Prerequisites:
# - External Secrets Operator installed in cluster
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
# ClusterSecretStore - Points to AWS Secrets Manager
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
            DATABASE_URL = "postgresql+asyncpg://${var.database_user}:{{ .password }}@${var.database_host}:5432/${var.database_name}"
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
