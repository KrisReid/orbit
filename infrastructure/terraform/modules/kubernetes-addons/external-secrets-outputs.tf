# =============================================================================
# External Secrets Operator - Outputs
# =============================================================================

output "external_secrets_namespace" {
  description = "The namespace where External Secrets Operator is installed"
  value       = var.enable_external_secrets ? var.external_secrets_namespace : null
}

output "external_secrets_service_account" {
  description = "The service account name for External Secrets Operator"
  value       = var.enable_external_secrets ? var.external_secrets_service_account_name : null
}
