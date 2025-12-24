# =============================================================================
# Orbit GKE Environment - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = module.vpc.network_name
}

output "vpc_subnet_name" {
  description = "The name of the VPC subnet"
  value       = module.vpc.subnet_name
}

# -----------------------------------------------------------------------------
# GKE Cluster Outputs
# -----------------------------------------------------------------------------
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = module.gke.kubeconfig_command
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------
output "database_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = module.database.instance_name
}

output "database_connection_name" {
  description = "The connection name for Cloud SQL Proxy"
  value       = module.database.instance_connection_name
}

output "database_private_ip" {
  description = "The private IP address of the database"
  value       = module.database.private_ip_address
}

# -----------------------------------------------------------------------------
# Application Outputs
# -----------------------------------------------------------------------------
output "orbit_namespace" {
  description = "The namespace where Orbit is deployed"
  value       = module.orbit.namespace
}

output "orbit_ingress_host" {
  description = "The ingress hostname for Orbit"
  value       = module.orbit.ingress_host
}

output "orbit_url" {
  description = "The URL to access Orbit"
  value       = module.orbit.ingress_url
}

# -----------------------------------------------------------------------------
# Kubernetes Addons Outputs
# -----------------------------------------------------------------------------
output "nginx_ingress_namespace" {
  description = "The namespace where NGINX Ingress Controller is installed"
  value       = module.kubernetes_addons.nginx_ingress_namespace
}

output "cert_manager_namespace" {
  description = "The namespace where cert-manager is installed"
  value       = module.kubernetes_addons.cert_manager_namespace
}
