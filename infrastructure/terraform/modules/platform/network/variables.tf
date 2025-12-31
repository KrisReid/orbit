# =============================================================================
# Platform Network Module - Variables
# =============================================================================
# Cloud-agnostic interface for VPC/network provisioning.
# =============================================================================

# -----------------------------------------------------------------------------
# Cloud Provider Selection
# -----------------------------------------------------------------------------
variable "cloud_provider" {
  description = "Cloud provider to deploy to: aws or gcp"
  type        = string

  validation {
    condition     = contains(["aws", "gcp"], var.cloud_provider)
    error_message = "cloud_provider must be one of: aws, gcp"
  }
}

# -----------------------------------------------------------------------------
# Provider-Specific Configuration
# -----------------------------------------------------------------------------
variable "aws_config" {
  description = "AWS-specific configuration"
  type = object({
    enable_vpc_endpoints = optional(bool, true)
  })
  default = null
}

variable "gcp_config" {
  description = "GCP-specific configuration (required when cloud_provider = gcp)"
  type = object({
    project_id               = string
    pods_cidr                = optional(string, "10.16.0.0/14")
    services_cidr            = optional(string, "10.20.0.0/20")
    enable_private_services  = optional(bool, true)
  })
  default = null
}

# -----------------------------------------------------------------------------
# Common Configuration
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "region" {
  description = "Cloud region for deployment"
  type        = string
}

variable "vpc_cidr" {
  description = "Primary CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_count" {
  description = "Number of availability zones to use (AWS only)"
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------
# NAT Configuration
# -----------------------------------------------------------------------------
variable "enable_nat" {
  description = "Enable NAT Gateway/Cloud NAT for private subnets"
  type        = bool
  default     = true
}

variable "single_nat" {
  description = "Use single NAT Gateway instead of one per AZ (cost saving, AWS only)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Subnet Configuration
# -----------------------------------------------------------------------------
variable "enable_database_subnets" {
  description = "Create database subnet group (AWS) or private services connection (GCP)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Kubernetes Integration
# -----------------------------------------------------------------------------
variable "kubernetes_cluster_name" {
  description = "Name of the Kubernetes cluster (for subnet tagging)"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Resource tags/labels"
  type        = map(string)
  default     = {}
}
