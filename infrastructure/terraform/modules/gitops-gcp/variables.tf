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
