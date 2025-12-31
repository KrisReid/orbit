# =============================================================================
# Platform GitOps Module - Outputs
# =============================================================================
# Normalized outputs regardless of cloud provider.
#
# Note: IAM Role ARN (AWS) and Service Account Email (GCP) for External Secrets
# are created in the environment module and not exposed here to avoid circular
# dependencies with kubernetes-addons.
# =============================================================================

output "application_namespace" {
  description = "Created application namespace"
  value = coalesce(
    try(module.aws[0].application_namespace, null),
    try(module.gcp[0].application_namespace, null)
  )
}

output "kubernetes_secret_name" {
  description = "Name of the Kubernetes secret containing database credentials"
  value = coalesce(
    try(module.aws[0].kubernetes_secret_name, null),
    try(module.gcp[0].kubernetes_secret_name, null)
  )
}

output "cluster_secret_store_name" {
  description = "Name of the ClusterSecretStore"
  value = coalesce(
    try(module.aws[0].cluster_secret_store_name, null),
    try(module.gcp[0].cluster_secret_store_name, null)
  )
}
