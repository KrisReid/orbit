# =============================================================================
# Kubernetes Addons Module
# =============================================================================
# Installs common Kubernetes addons: NGINX Ingress Controller and cert-manager.
# This module is cloud-agnostic and works with both GKE and EKS.
# =============================================================================

# -----------------------------------------------------------------------------
# NGINX Ingress Controller
# -----------------------------------------------------------------------------
resource "helm_release" "nginx_ingress" {
  count = var.enable_nginx_ingress ? 1 : 0

  name             = "ingress-nginx"
  namespace        = var.nginx_namespace
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.nginx_chart_version

  values = [
    yamlencode({
      controller = {
        replicaCount = var.nginx_replica_count

        resources = var.nginx_resources

        service = {
          type = var.nginx_service_type
          annotations = var.nginx_service_annotations
        }

        config = var.nginx_config

        metrics = {
          enabled = var.enable_nginx_metrics
          serviceMonitor = {
            enabled = var.enable_nginx_service_monitor
          }
        }

        admissionWebhooks = {
          enabled = var.enable_nginx_admission_webhooks
        }

        autoscaling = var.enable_nginx_autoscaling ? {
          enabled     = true
          minReplicas = var.nginx_min_replicas
          maxReplicas = var.nginx_max_replicas
          targetCPUUtilizationPercentage = var.nginx_target_cpu_utilization
        } : {
          enabled = false
        }
      }
    })
  ]

  dynamic "set" {
    for_each = var.nginx_extra_values
    content {
      name  = set.key
      value = set.value
    }
  }

  timeout = var.helm_timeout
}

# -----------------------------------------------------------------------------
# cert-manager
# -----------------------------------------------------------------------------
resource "helm_release" "cert_manager" {
  count = var.enable_cert_manager ? 1 : 0

  name             = "cert-manager"
  namespace        = var.cert_manager_namespace
  create_namespace = true
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_chart_version

  set {
    name  = "installCRDs"
    value = "true"
  }

  values = [
    yamlencode({
      replicaCount = var.cert_manager_replica_count

      resources = var.cert_manager_resources

      prometheus = {
        enabled = var.enable_cert_manager_metrics
        servicemonitor = {
          enabled = var.enable_cert_manager_service_monitor
        }
      }

      webhook = {
        replicaCount = var.cert_manager_webhook_replica_count
      }

      cainjector = {
        replicaCount = var.cert_manager_cainjector_replica_count
      }
    })
  ]

  dynamic "set" {
    for_each = var.cert_manager_extra_values
    content {
      name  = set.key
      value = set.value
    }
  }

  timeout = var.helm_timeout

  depends_on = [helm_release.nginx_ingress]
}

# -----------------------------------------------------------------------------
# Let's Encrypt ClusterIssuers
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "letsencrypt_staging" {
  count = var.enable_cert_manager && var.create_letsencrypt_issuers ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-staging-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  })

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "letsencrypt_prod" {
  count = var.enable_cert_manager && var.create_letsencrypt_issuers ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-prod-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  })

  depends_on = [helm_release.cert_manager]
}
