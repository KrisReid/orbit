# =============================================================================
# GitOps GCP Module - Variables
# =============================================================================

# -----------------------------------------------------------------------------
# GCP Configuration
# -----------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "cluster_location" {
  description = "Location of the GKE cluster (region or zone)"
  type        = string
}

# -----------------------------------------------------------------------------
# External Secrets Configuration
# -----------------------------------------------------------------------------
variable "external_secrets_namespace" {
  description = "Namespace where External Secrets Operator is installed"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_service_account" {
  description = "Name of the External Secrets Operator service account"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_ready" {
  description = "Dependency marker - pass the helm_release resource to ensure ESO is ready"
  type        = any
  default     = null
}

variable "secret_refresh_interval" {
  description = "How often to refresh secrets from GCP Secret Manager"
  type        = string
  default     = "1h"
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "database_host" {
  description = "Database host (Cloud SQL private IP)"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "orbit"
}

variable "database_user" {
  description = "Database username"
  type        = string
  default     = "orbit"
}

variable "database_secret_id" {
  description = "GCP Secret Manager secret ID containing the database password"
  type        = string
}

# -----------------------------------------------------------------------------
# Application Configuration
# -----------------------------------------------------------------------------
variable "application_namespace" {
  description = "Kubernetes namespace for the Orbit application"
  type        = string
  default     = "orbit"
}

# -----------------------------------------------------------------------------
# ArgoCD Configuration
# -----------------------------------------------------------------------------
variable "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  type        = string
  default     = "argocd"
}

variable "deploy_argocd_application" {
  description = "Deploy the ArgoCD Application resource"
  type        = bool
  default     = true
}

variable "enable_argocd_finalizer" {
  description = "Enable ArgoCD resource finalizer (prevents orphan resources on delete)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Git Repository Configuration
# -----------------------------------------------------------------------------
variable "git_repo_url" {
  description = "Git repository URL for the Orbit Helm chart"
  type        = string
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
# Ingress Configuration
# -----------------------------------------------------------------------------
variable "enable_ingress" {
  description = "Enable ingress for the application"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Hostname for the ingress"
  type        = string
}

variable "enable_tls" {
  description = "Enable TLS for the ingress"
  type        = bool
  default     = true
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer to use for TLS"
  type        = string
  default     = "letsencrypt-prod"
}

# -----------------------------------------------------------------------------
# Sync Configuration
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
