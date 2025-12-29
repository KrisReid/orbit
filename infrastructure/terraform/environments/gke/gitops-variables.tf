# =============================================================================
# Orbit GKE Environment - GitOps Variables
# =============================================================================
# Variables for External Secrets Operator, ArgoCD, and GitOps bootstrap.
# =============================================================================

# -----------------------------------------------------------------------------
# ArgoCD Configuration
# -----------------------------------------------------------------------------
variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
  default     = true
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
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
  description = "How often to refresh secrets from GCP Secret Manager"
  type        = string
  default     = "1h"
}

# -----------------------------------------------------------------------------
# GitOps Bootstrap Configuration
# -----------------------------------------------------------------------------
variable "enable_gitops_bootstrap" {
  description = "Enable GitOps bootstrap (creates SecretStore, ExternalSecret, and ArgoCD Application)"
  type        = bool
  default     = true
}

variable "application_namespace" {
  description = "Kubernetes namespace for the Orbit application"
  type        = string
  default     = "orbit"
}

variable "deploy_argocd_application" {
  description = "Deploy the ArgoCD Application resource"
  type        = bool
  default     = true
}

variable "enable_argocd_finalizer" {
  description = "Enable ArgoCD resource finalizer"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Git Repository Configuration
# -----------------------------------------------------------------------------
variable "git_repo_url" {
  description = "Git repository URL for the Orbit Helm chart (e.g., https://github.com/YOUR_ORG/orbit.git)"
  type        = string
  default     = ""
}

variable "git_target_revision" {
  description = "Git branch, tag, or commit to deploy"
  type        = string
  default     = "main"
}

variable "helm_chart_path" {
  description = "Path to the Helm chart in the Git repository"
  type        = string
  default     = "infrastructure/helm/orbit"
}

variable "helm_value_files" {
  description = "List of Helm value files to use"
  type        = list(string)
  default     = ["values.yaml", "values-production.yaml"]
}

# -----------------------------------------------------------------------------
# Container Images
# -----------------------------------------------------------------------------
variable "backend_image_repository" {
  description = "Backend container image repository"
  type        = string
  default     = "ghcr.io/YOUR_ORG/orbit-backend"
}

variable "backend_image_tag" {
  description = "Backend container image tag"
  type        = string
  default     = "latest"
}

variable "frontend_image_repository" {
  description = "Frontend container image repository"
  type        = string
  default     = "ghcr.io/YOUR_ORG/orbit-frontend"
}

variable "frontend_image_tag" {
  description = "Frontend container image tag"
  type        = string
  default     = "latest"
}

# -----------------------------------------------------------------------------
# Application Ingress Configuration
# -----------------------------------------------------------------------------
variable "enable_app_ingress" {
  description = "Enable ingress for the Orbit application"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Hostname for the application ingress (e.g., orbit.example.com)"
  type        = string
  default     = ""
}

variable "enable_tls" {
  description = "Enable TLS for the application ingress"
  type        = bool
  default     = true
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer to use for TLS certificates"
  type        = string
  default     = "letsencrypt-prod"
}

# -----------------------------------------------------------------------------
# ArgoCD Sync Configuration
# -----------------------------------------------------------------------------
variable "enable_auto_sync" {
  description = "Enable automatic sync in ArgoCD"
  type        = bool
  default     = true
}

variable "auto_sync_prune" {
  description = "Enable automatic pruning of resources"
  type        = bool
  default     = true
}

variable "auto_sync_self_heal" {
  description = "Enable automatic self-healing"
  type        = bool
  default     = true
}
