# =============================================================================
# Kubernetes Addons Module
# =============================================================================
# Installs common Kubernetes addons: NGINX Ingress, cert-manager, ArgoCD, ESO.
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
    yamlencode(merge(
      {
        controller = {
          replicaCount = var.nginx_replica_count

          resources = var.nginx_resources

          service = {
            type        = var.nginx_service_type
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

          autoscaling = {
            enabled                        = var.enable_nginx_autoscaling
            minReplicas                    = var.nginx_min_replicas
            maxReplicas                    = var.nginx_max_replicas
            targetCPUUtilizationPercentage = var.nginx_target_cpu_utilization
          }
        }
      },
      var.nginx_extra_values
    ))
  ]

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

  values = [
    yamlencode(merge(
      {
        installCRDs  = true
        replicaCount = var.cert_manager_replica_count
        resources    = var.cert_manager_resources
        prometheus = {
          enabled = var.enable_cert_manager_metrics
          servicemonitor = {
            enabled = var.enable_cert_manager_service_monitor
          }
        }
      },
      var.cert_manager_extra_values
    ))
  ]

  timeout = var.helm_timeout
}

# -----------------------------------------------------------------------------
# Let's Encrypt ClusterIssuers
# -----------------------------------------------------------------------------
resource "kubectl_manifest" "letsencrypt_staging" {
  count = var.enable_cert_manager && var.create_letsencrypt_issuers && var.letsencrypt_email != "" ? 1 : 0

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
          name = "letsencrypt-staging"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  })

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "letsencrypt_prod" {
  count = var.enable_cert_manager && var.create_letsencrypt_issuers && var.letsencrypt_email != "" ? 1 : 0

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
          name = "letsencrypt-prod"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  })

  depends_on = [helm_release.cert_manager]
}

# -----------------------------------------------------------------------------
# ArgoCD
# -----------------------------------------------------------------------------
resource "helm_release" "argocd" {
  count = var.enable_argocd ? 1 : 0

  name             = "argocd"
  namespace        = var.argocd_namespace
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version

  values = [
    yamlencode(merge(
      {
        server = {
          replicas = var.argocd_server_replicas
        }
        configs = {
          params = {
            "server.insecure" = true
          }
        }
      },
      var.argocd_extra_values
    ))
  ]

  timeout = var.helm_timeout
}

# -----------------------------------------------------------------------------
# External Secrets Operator
# -----------------------------------------------------------------------------
resource "helm_release" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  name             = "external-secrets"
  namespace        = var.external_secrets_namespace
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version

  values = [
    yamlencode(merge(
      {
        serviceAccount = {
          annotations = var.external_secrets_service_account_annotations
        }
        installCRDs = true
      },
      var.external_secrets_extra_values
    ))
  ]

  timeout = var.helm_timeout
}
