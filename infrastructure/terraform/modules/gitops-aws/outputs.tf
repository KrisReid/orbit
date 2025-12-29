# =============================================================================
# GitOps AWS Module - Outputs
# =============================================================================

output "secret_store_name" {
  description = "Name of the ClusterSecretStore"
  value       = "aws-secrets-manager"
}

output "external_secret_name" {
  description = "Name of the ExternalSecret for database credentials"
  value       = "orbit-db-credentials"
}

output "kubernetes_secret_name" {
  description = "Name of the Kubernetes secret created by External Secrets"
  value       = "orbit-db-credentials"
}

output "application_namespace" {
  description = "Namespace where the application is deployed"
  value       = var.application_namespace
}

output "argocd_application_name" {
  description = "Name of the ArgoCD Application"
  value       = var.deploy_argocd_application ? "orbit" : null
}

output "external_secrets_role_arn" {
  description = "ARN of the IAM role for External Secrets Operator"
  value       = var.create_irsa_role ? aws_iam_role.external_secrets[0].arn : null
}

output "external_secrets_role_name" {
  description = "Name of the IAM role for External Secrets Operator"
  value       = var.create_irsa_role ? aws_iam_role.external_secrets[0].name : null
}
