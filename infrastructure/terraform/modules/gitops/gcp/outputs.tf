# =============================================================================
# GitOps GCP Module - Outputs
# =============================================================================

output "application_namespace" {
  description = "The application namespace"
  value       = kubernetes_namespace_v1.application.metadata[0].name
}

output "kubernetes_secret_name" {
  description = "The Kubernetes secret name containing database credentials"
  value       = var.kubernetes_secret_name
}

output "cluster_secret_store_name" {
  description = "The name of the ClusterSecretStore"
  value       = local.secret_store_name
}
