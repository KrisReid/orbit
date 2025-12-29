# =============================================================================
# External Secrets Operator
# =============================================================================
# Syncs secrets from external secret stores (GCP Secret Manager, AWS Secrets 
# Manager, etc.) into Kubernetes secrets.
# =============================================================================

resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name             = "external-secrets"
  namespace        = var.external_secrets_namespace
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version

  values = [
    yamlencode({
      replicaCount = var.external_secrets_replica_count

      resources = var.external_secrets_resources

      serviceAccount = {
        create = true
        name   = var.external_secrets_service_account_name
        annotations = var.external_secrets_service_account_annotations
      }

      webhook = {
        replicaCount = var.external_secrets_webhook_replica_count
      }

      certController = {
        replicaCount = var.external_secrets_cert_controller_replica_count
      }

      prometheus = {
        enabled = var.enable_external_secrets_metrics
        service = {
          enabled = var.enable_external_secrets_metrics
        }
      }
    })
  ]

  set = [for k, v in var.external_secrets_extra_values : {
    name  = k
    value = v
  }]

  timeout = var.helm_timeout

  depends_on = [helm_release.cert_manager]
}
