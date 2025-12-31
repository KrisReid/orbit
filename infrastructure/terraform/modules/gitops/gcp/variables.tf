# =============================================================================
# GitOps GCP Module - Variables
# =============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "cluster_location" {
  description = "GKE cluster location (region or zone)"
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
  description = "Kubernetes service account name for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_ready" {
  description = "Dependency marker - pass the kubernetes_addons module output"
  type        = any
  default     = null
}

variable "secret_refresh_interval" {
  description = "How often to sync secrets from GCP Secret Manager"
  type        = string
  default     = "1h"
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "database_host" {
  description = "Database hostname"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_user" {
  description = "Database username"
  type        = string
}

variable "database_secret_id" {
  description = "GCP Secret Manager secret ID containing database credentials"
  type        = string
}

# -----------------------------------------------------------------------------
# Application Configuration
# -----------------------------------------------------------------------------
variable "application_namespace" {
  description = "Namespace to create for the application"
  type        = string
  default     = "orbit"
}

variable "kubernetes_secret_name" {
  description = "Name of the Kubernetes secret to create"
  type        = string
  default     = "orbit-database"
}
