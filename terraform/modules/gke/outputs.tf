# =============================================================================
# GKE Cluster Module - Outputs
# =============================================================================

output "cluster_id" {
  description = "The unique identifier of the cluster"
  value       = google_container_cluster.main.id
}

output "cluster_name" {
  description = "The name of the cluster"
  value       = google_container_cluster.main.name
}

output "cluster_location" {
  description = "The location of the cluster"
  value       = google_container_cluster.main.location
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = google_container_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The public certificate that is the root of trust for the cluster"
  value       = base64decode(google_container_cluster.main.master_auth[0].cluster_ca_certificate)
  sensitive   = true
}

output "cluster_master_version" {
  description = "The current version of the master in the cluster"
  value       = google_container_cluster.main.master_version
}

output "cluster_self_link" {
  description = "The self_link of the cluster"
  value       = google_container_cluster.main.self_link
}

output "node_pools" {
  description = "List of node pools"
  value       = { for k, v in google_container_node_pool.main : k => v.name }
}

# Kubeconfig helper
output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.main.name} --region ${google_container_cluster.main.location} --project ${var.project_id}"
}
