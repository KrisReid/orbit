# =============================================================================
# GitOps AWS Module - Variables
# =============================================================================

variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
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
  description = "How often to sync secrets from AWS Secrets Manager"
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

variable "database_secret_name" {
  description = "Name of the AWS Secrets Manager secret containing database credentials"
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

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
