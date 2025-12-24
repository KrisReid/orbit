# =============================================================================
# Orbit Application Module
# =============================================================================
# Deploys the Orbit application using the Helm chart.
# This module is cloud-agnostic and works with both GKE and EKS.
# =============================================================================

resource "helm_release" "orbit" {
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = var.create_namespace
  chart            = var.chart_path
  version          = var.chart_version

  values = [
    yamlencode({
      # Global settings
      global = {
        imagePullSecrets = var.image_pull_secrets
        storageClass     = var.storage_class
      }

      # Backend configuration
      backend = {
        replicaCount = var.backend_replica_count
        image = {
          repository = var.backend_image_repository
          tag        = var.backend_image_tag
          pullPolicy = var.image_pull_policy
        }
        resources = var.backend_resources
        env = merge({
          DEBUG          = var.debug_mode ? "true" : "false"
          TASK_ID_PREFIX = var.task_id_prefix
        }, var.backend_env)
        autoscaling = {
          enabled                        = var.backend_autoscaling_enabled
          minReplicas                    = var.backend_min_replicas
          maxReplicas                    = var.backend_max_replicas
          targetCPUUtilizationPercentage = var.backend_target_cpu
        }
      }

      # Frontend configuration
      frontend = {
        replicaCount = var.frontend_replica_count
        image = {
          repository = var.frontend_image_repository
          tag        = var.frontend_image_tag
          pullPolicy = var.image_pull_policy
        }
        resources = var.frontend_resources
        autoscaling = {
          enabled                        = var.frontend_autoscaling_enabled
          minReplicas                    = var.frontend_min_replicas
          maxReplicas                    = var.frontend_max_replicas
          targetCPUUtilizationPercentage = var.frontend_target_cpu
        }
      }

      # Ingress configuration
      ingress = {
        enabled   = var.ingress_enabled
        className = var.ingress_class_name
        annotations = merge(
          var.ingress_tls_enabled ? {
            "cert-manager.io/cluster-issuer" = var.cert_manager_issuer
          } : {},
          var.ingress_annotations
        )
        host = var.ingress_host
        tls = {
          enabled    = var.ingress_tls_enabled
          secretName = var.ingress_tls_secret_name
        }
      }

      # PostgreSQL subchart (disabled when using external database)
      postgresql = {
        enabled = !var.use_external_database
        auth = {
          username = var.database_user
          password = var.database_password
          database = var.database_name
        }
        primary = {
          persistence = {
            enabled      = true
            size         = var.postgresql_storage_size
            storageClass = var.storage_class
          }
          resources = var.postgresql_resources
        }
      }

      # External database configuration
      externalDatabase = {
        enabled                     = var.use_external_database
        host                        = var.external_database_host
        port                        = var.external_database_port
        database                    = var.database_name
        username                    = var.database_user
        password                    = var.database_password
        existingSecret              = var.external_database_secret
        existingSecretPasswordKey   = var.external_database_secret_key
      }

      # Service Account
      serviceAccount = {
        create      = var.create_service_account
        annotations = var.service_account_annotations
        name        = var.service_account_name
      }

      # Network Policy
      networkPolicy = {
        enabled = var.enable_network_policy
      }

      # Pod Disruption Budget
      podDisruptionBudget = {
        enabled      = var.enable_pdb
        minAvailable = var.pdb_min_available
      }
    })
  ]

  # Additional values for customization
  dynamic "set" {
    for_each = var.extra_set_values
    content {
      name  = set.key
      value = set.value
    }
  }

  dynamic "set_sensitive" {
    for_each = var.extra_sensitive_values
    content {
      name  = set_sensitive.key
      value = set_sensitive.value
    }
  }

  timeout = var.helm_timeout
  wait    = var.wait_for_deployment

  depends_on = var.depends_on_resources
}
