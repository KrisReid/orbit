# =============================================================================
# Platform Database Module - Outputs
# =============================================================================
# Normalized outputs regardless of cloud provider.
# =============================================================================

output "instance_id" {
  description = "Cloud-specific instance identifier"
  value = coalesce(
    try(module.aws[0].instance_id, null),
    try(module.gcp[0].instance_name, null)
  )
}

output "host" {
  description = "Database hostname/IP for connections"
  value = coalesce(
    try(module.aws[0].instance_address, null),
    try(module.gcp[0].private_ip_address, null)
  )
}

output "port" {
  description = "Database port"
  value       = 5432
}

output "database_name" {
  description = "Name of the created database"
  value = coalesce(
    try(module.aws[0].database_name, null),
    try(module.gcp[0].database_name, null)
  )
}

output "database_user" {
  description = "Master username"
  value = coalesce(
    try(module.aws[0].database_user, null),
    try(module.gcp[0].database_user, null)
  )
}

output "database_password" {
  description = "Master password"
  value = coalesce(
    try(module.aws[0].database_password, null),
    try(module.gcp[0].database_password, null)
  )
  sensitive = true
}

output "connection_string" {
  description = "Full PostgreSQL connection URI"
  value = coalesce(
    try(module.aws[0].connection_string, null),
    try(module.gcp[0].connection_string, null)
  )
  sensitive = true
}

# -----------------------------------------------------------------------------
# Secret References
# -----------------------------------------------------------------------------
output "secret_id" {
  description = "Cloud secret ID/name containing credentials"
  value = coalesce(
    try(module.aws[0].secret_name, null),
    try(module.gcp[0].secret_id, null)
  )
}

output "secret_arn" {
  description = "Cloud secret ARN (AWS only)"
  value       = try(module.aws[0].secret_arn, null)
}

# -----------------------------------------------------------------------------
# Provider-Specific Outputs
# -----------------------------------------------------------------------------
output "provider_specific" {
  description = "Provider-specific outputs for advanced configuration"
  value = {
    aws = var.cloud_provider == "aws" ? {
      instance_arn      = try(module.aws[0].instance_arn, null)
      instance_endpoint = try(module.aws[0].instance_endpoint, null)
      security_group_id = try(module.aws[0].security_group_id, null)
    } : null

    gcp = var.cloud_provider == "gcp" ? {
      instance_connection_name = try(module.gcp[0].instance_connection_name, null)
      instance_self_link       = try(module.gcp[0].instance_self_link, null)
    } : null
  }
}
