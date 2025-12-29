# =============================================================================
# GitOps GCP Module - Outputs
# =============================================================================

output "secret_store_name" {
  description = "Name of the ClusterSecretStore"
  value       = "gcp-secret-manager"
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
