# =============================================================================
# Orbit EKS Environment - GitOps Variables
# =============================================================================
# Variables for External Secrets Operator, ArgoCD, and GitOps bootstrap.
#
# Note: ArgoCD Application configuration is managed via GitOps using the
# overlays in infrastructure/argocd/overlays/
# =============================================================================

# -----------------------------------------------------------------------------
# ArgoCD Configuration
# -----------------------------------------------------------------------------
variable "enable_argocd" {
  description = "Enable ArgoCD installation"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# External Secrets Configuration
# -----------------------------------------------------------------------------
variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = true
}

variable "external_secrets_namespace" {
  description = "Namespace for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_service_account" {
  description = "Service account name for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "secret_refresh_interval" {
  description = "How often to refresh secrets from AWS Secrets Manager"
  type        = string
  default     = "1h"
}

# -----------------------------------------------------------------------------
# GitOps Bootstrap Configuration
# -----------------------------------------------------------------------------
variable "enable_gitops_bootstrap" {
  description = "Enable GitOps bootstrap (creates ClusterSecretStore, ExternalSecret, and application namespace)"
  type        = bool
  default     = true
}

variable "application_namespace" {
  description = "Kubernetes namespace for the Orbit application"
  type        = string
  default     = "orbit"
}
