# =============================================================================
# GKE Cluster Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster Outputs (Required by Interface Contract)
# -----------------------------------------------------------------------------
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.main.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster (base64 decoded)"
  value       = base64decode(google_container_cluster.main.master_auth[0].cluster_ca_certificate)
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${var.region} --project ${var.project_id}"
}

# -----------------------------------------------------------------------------
# Workload Identity Outputs
# -----------------------------------------------------------------------------
output "workload_identity_pool" {
  description = "The Workload Identity Pool for the cluster"
  value       = "${var.project_id}.svc.id.goog"
}

# -----------------------------------------------------------------------------
# Additional Outputs
# -----------------------------------------------------------------------------
output "cluster_id" {
  description = "The unique identifier of the cluster"
  value       = google_container_cluster.main.id
}

output "cluster_location" {
  description = "The location of the cluster"
  value       = google_container_cluster.main.location
}

output "cluster_self_link" {
  description = "The self_link of the cluster"
  value       = google_container_cluster.main.self_link
}

output "cluster_master_version" {
  description = "The current version of the master"
  value       = google_container_cluster.main.master_version
}

output "node_service_account" {
  description = "The service account used by node pools"
  value       = local.node_service_account
}

output "node_pools" {
  description = "The node pools created for the cluster"
  value       = { for k, v in google_container_node_pool.main : k => v.name }
}
