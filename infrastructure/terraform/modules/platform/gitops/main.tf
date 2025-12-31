# =============================================================================
# Platform GitOps Module
# =============================================================================
# Cloud-agnostic facade that routes to provider-specific implementations.
#
# Note: IAM roles (AWS) and Service Accounts (GCP) for External Secrets are
# created in the environment module to avoid circular dependencies with
# kubernetes-addons. This module only creates the Kubernetes resources.
# =============================================================================

# -----------------------------------------------------------------------------
# AWS GitOps Implementation
# -----------------------------------------------------------------------------
module "aws" {
  source = "../../gitops/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  region       = var.region
  cluster_name = var.cluster_name

  # External Secrets configuration
  external_secrets_namespace       = var.external_secrets_namespace
  external_secrets_service_account = var.external_secrets_service_account
  external_secrets_ready           = var.external_secrets_ready
  secret_refresh_interval          = var.secret_refresh_interval

  # Database configuration
  database_host        = var.database_host
  database_name        = var.database_name
  database_user        = var.database_user
  database_secret_name = var.database_secret_id

  # Application configuration
  application_namespace  = var.application_namespace
  kubernetes_secret_name = var.kubernetes_secret_name

  tags = var.tags
}

# -----------------------------------------------------------------------------
# GCP GitOps Implementation
# -----------------------------------------------------------------------------
module "gcp" {
  source = "../../gitops/gcp"
  count  = var.cloud_provider == "gcp" ? 1 : 0

  project_id = var.gcp_config.project_id

  cluster_name     = var.cluster_name
  cluster_location = var.gcp_config.cluster_location

  # External Secrets configuration
  external_secrets_namespace       = var.external_secrets_namespace
  external_secrets_service_account = var.external_secrets_service_account
  external_secrets_ready           = var.external_secrets_ready
  secret_refresh_interval          = var.secret_refresh_interval

  # Database configuration
  database_host      = var.database_host
  database_name      = var.database_name
  database_user      = var.database_user
  database_secret_id = var.database_secret_id

  # Application configuration
  application_namespace  = var.application_namespace
  kubernetes_secret_name = var.kubernetes_secret_name
}
