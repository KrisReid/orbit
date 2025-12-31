# =============================================================================
# Platform Network Module - Outputs
# =============================================================================
# Normalized outputs regardless of cloud provider.
# =============================================================================

# -----------------------------------------------------------------------------
# Core VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC/Network ID"
  value = coalesce(
    try(module.aws[0].vpc_id, null),
    try(module.gcp[0].network_id, null)
  )
}

output "vpc_cidr" {
  description = "VPC primary CIDR block"
  value = coalesce(
    try(module.aws[0].vpc_cidr_block, null),
    try(var.vpc_cidr, null)
  )
}

# -----------------------------------------------------------------------------
# Subnet Outputs
# -----------------------------------------------------------------------------
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = coalesce(
    try(module.aws[0].public_subnet_ids, null),
    try([], null)  # GCP doesn't have separate public subnets
  )
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = coalesce(
    try(module.aws[0].private_subnet_ids, null),
    try([module.gcp[0].subnet_id], null)
  )
}

output "availability_zones" {
  description = "List of availability zones used"
  value = coalesce(
    try(module.aws[0].availability_zones, null),
    try([var.region], null)
  )
}

# -----------------------------------------------------------------------------
# Database Connectivity
# -----------------------------------------------------------------------------
output "database_subnet_group_name" {
  description = "Database subnet group name (AWS only)"
  value       = try(module.aws[0].db_subnet_group_name, null)
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value = coalesce(
    try(module.aws[0].private_subnet_ids, null),
    try([module.gcp[0].subnet_id], null)
  )
}

# -----------------------------------------------------------------------------
# NAT Outputs
# -----------------------------------------------------------------------------
output "nat_gateway_ips" {
  description = "NAT Gateway public IPs"
  value = coalesce(
    try([for nat in module.aws[0].nat_gateway_ids : nat], null),
    try(module.gcp[0].nat_ip_addresses, null),
    []
  )
}

# -----------------------------------------------------------------------------
# GCP-Specific Outputs
# -----------------------------------------------------------------------------
output "vpc_self_link" {
  description = "VPC self_link (GCP only)"
  value       = try(module.gcp[0].network_self_link, null)
}

output "subnet_self_link" {
  description = "Subnet self_link (GCP only)"
  value       = try(module.gcp[0].subnet_self_link, null)
}

output "pods_range_name" {
  description = "Secondary range name for pods (GCP only)"
  value       = try(module.gcp[0].pods_range_name, null)
}

output "services_range_name" {
  description = "Secondary range name for services (GCP only)"
  value       = try(module.gcp[0].services_range_name, null)
}

output "private_services_connection" {
  description = "Private services connection ID (GCP only)"
  value       = try(module.gcp[0].private_services_connection, null)
}

# -----------------------------------------------------------------------------
# Provider-Specific Outputs (for advanced use cases)
# -----------------------------------------------------------------------------
output "provider_specific" {
  description = "Provider-specific outputs for advanced configuration"
  value = {
    aws = var.cloud_provider == "aws" ? {
      vpc_id              = try(module.aws[0].vpc_id, null)
      db_subnet_group_arn = try(module.aws[0].db_subnet_group_arn, null)
      public_subnet_cidrs = try(module.aws[0].public_subnet_cidrs, null)
      private_subnet_cidrs = try(module.aws[0].private_subnet_cidrs, null)
    } : null

    gcp = var.cloud_provider == "gcp" ? {
      network_name               = try(module.gcp[0].network_name, null)
      subnet_name                = try(module.gcp[0].subnet_name, null)
      private_services_connection = try(module.gcp[0].private_services_connection, null)
    } : null
  }
}
