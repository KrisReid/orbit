# =============================================================================
# GitOps AWS Module - Variables
# =============================================================================

# -----------------------------------------------------------------------------
# AWS Configuration
# -----------------------------------------------------------------------------
variable "region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for IRSA"
  type        = string
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# IRSA Configuration
# -----------------------------------------------------------------------------
variable "create_irsa_role" {
  description = "Create IAM role for External Secrets Operator (IRSA)"
  type        = bool
  default     = true
}

variable "allowed_secret_arns" {
  description = "List of Secret Manager ARNs the role can access (null = all secrets)"
  type        = list(string)
  default     = null
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
  description = "How often to refresh secrets from AWS Secrets Manager"
  type        = string
  default     = "1h"
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "database_host" {
  description = "Database host (RDS endpoint)"
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

variable "database_secret_name" {
  description = "AWS Secrets Manager secret name containing the database password"
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
