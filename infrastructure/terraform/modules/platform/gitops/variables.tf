# =============================================================================
# Platform GitOps Module - Variables
# =============================================================================
# Cloud-agnostic interface for GitOps bootstrap (External Secrets + Namespace).
#
# Note: IAM roles (AWS) and Service Accounts (GCP) for External Secrets are
# created in the environment module to avoid circular dependencies.
# =============================================================================

# -----------------------------------------------------------------------------
# Cloud Provider Selection
# -----------------------------------------------------------------------------
variable "cloud_provider" {
  description = "Cloud provider: aws or gcp"
  type        = string

  validation {
    condition     = contains(["aws", "gcp"], var.cloud_provider)
    error_message = "cloud_provider must be one of: aws, gcp"
  }
}

# -----------------------------------------------------------------------------
# Provider-Specific Configuration
# -----------------------------------------------------------------------------
variable "aws_config" {
  description = "AWS-specific configuration (optional, reserved for future use)"
  type        = any
  default     = null
}

variable "gcp_config" {
  description = "GCP-specific configuration (required when cloud_provider = gcp)"
  type = object({
    project_id       = string
    cluster_location = string
  })
  default = null
}

# -----------------------------------------------------------------------------
# Cluster Configuration
# -----------------------------------------------------------------------------
variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "region" {
  description = "Cloud region"
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

# -----------------------------------------------------------------------------
# External Secrets Configuration
# -----------------------------------------------------------------------------
variable "external_secrets_namespace" {
  description = "Namespace where External Secrets Operator is installed"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_service_account" {
  description = "Service account name for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_ready" {
  description = "Dependency marker - pass the kubernetes_addons module output"
  type        = any
  default     = null
}

variable "secret_refresh_interval" {
  description = "How often to sync secrets from cloud provider"
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
  description = "Cloud secret ID containing database credentials"
  type        = string
}

# -----------------------------------------------------------------------------
# Kubernetes Secret Configuration
# -----------------------------------------------------------------------------
variable "kubernetes_secret_name" {
  description = "Name of the Kubernetes secret to create"
  type        = string
  default     = "orbit-database"
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Resource tags/labels"
  type        = map(string)
  default     = {}
}
