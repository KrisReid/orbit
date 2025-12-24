# =============================================================================
# Orbit Application Module - Outputs
# =============================================================================

output "release_name" {
  description = "The Helm release name"
  value       = helm_release.orbit.name
}

output "namespace" {
  description = "The namespace where Orbit is deployed"
  value       = helm_release.orbit.namespace
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.orbit.status
}

output "ingress_host" {
  description = "The ingress hostname"
  value       = var.ingress_enabled ? var.ingress_host : null
}

output "ingress_url" {
  description = "The full URL to access Orbit"
  value       = var.ingress_enabled ? "${var.ingress_tls_enabled ? "https" : "http"}://${var.ingress_host}" : null
}
