# =============================================================================
# External Secrets Operator - Variables
# =============================================================================

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = false
}

variable "external_secrets_namespace" {
  description = "Namespace for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_chart_version" {
  description = "External Secrets Operator Helm chart version"
  type        = string
  default     = "0.9.11"
}

variable "external_secrets_replica_count" {
  description = "Number of External Secrets Operator replicas"
  type        = number
  default     = 1
}

variable "external_secrets_resources" {
  description = "Resource requests and limits for External Secrets Operator"
  type = object({
    requests = optional(object({
      cpu    = optional(string, "50m")
      memory = optional(string, "64Mi")
    }), {})
    limits = optional(object({
      cpu    = optional(string, "200m")
      memory = optional(string, "256Mi")
    }), {})
  })
  default = {}
}

variable "external_secrets_service_account_name" {
  description = "Service account name for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_service_account_annotations" {
  description = "Annotations for the External Secrets Operator service account (e.g., for Workload Identity)"
  type        = map(string)
  default     = {}
}

variable "external_secrets_webhook_replica_count" {
  description = "Number of External Secrets webhook replicas"
  type        = number
  default     = 1
}

variable "external_secrets_cert_controller_replica_count" {
  description = "Number of External Secrets cert controller replicas"
  type        = number
  default     = 1
}

variable "enable_external_secrets_metrics" {
  description = "Enable Prometheus metrics for External Secrets Operator"
  type        = bool
  default     = false
}

variable "external_secrets_extra_values" {
  description = "Extra Helm values for External Secrets Operator"
  type        = map(string)
  default     = {}
}
