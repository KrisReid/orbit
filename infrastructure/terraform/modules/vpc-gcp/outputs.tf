# =============================================================================
# GCP VPC Module - Outputs
# =============================================================================

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "The self_link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.main.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.main.name
}

output "subnet_self_link" {
  description = "The self_link of the subnet"
  value       = google_compute_subnetwork.main.self_link
}

output "pods_range_name" {
  description = "The name of the secondary IP range for pods"
  value       = google_compute_subnetwork.main.secondary_ip_range[0].range_name
}

output "services_range_name" {
  description = "The name of the secondary IP range for services"
  value       = google_compute_subnetwork.main.secondary_ip_range[1].range_name
}

output "private_services_connection" {
  description = "The private services connection for Cloud SQL"
  value       = var.enable_private_services ? google_service_networking_connection.private_services[0].id : null
}
