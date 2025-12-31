# =============================================================================
# Platform Database Module - Variables
# =============================================================================
# Cloud-agnostic interface for managed PostgreSQL databases.
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
  description = "AWS-specific configuration (required when cloud_provider = aws)"
  type = object({
    vpc_id                       = string
    db_subnet_group_name         = string
    allowed_security_groups      = optional(list(string), [])
    performance_insights_enabled = optional(bool, false)
    monitoring_interval          = optional(number, 0)
  })
  default = null
}

variable "gcp_config" {
  description = "GCP-specific configuration (required when cloud_provider = gcp)"
  type = object({
    project_id       = string
    private_network  = string  # VPC self_link
    insights_enabled = optional(bool, false)
  })
  default = null
}

# -----------------------------------------------------------------------------
# Common Configuration
# -----------------------------------------------------------------------------
variable "name" {
  description = "Name of the database instance"
  type        = string
}

variable "region" {
  description = "Cloud region for deployment"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "instance_size" {
  description = "Normalized instance size: small, medium, large, xlarge"
  type        = string
  default     = "small"

  validation {
    condition     = contains(["small", "medium", "large", "xlarge"], var.instance_size)
    error_message = "instance_size must be one of: small, medium, large, xlarge"
  }
}

variable "storage_gb" {
  description = "Initial storage allocation in GB"
  type        = number
  default     = 20
}

variable "storage_autoscaling" {
  description = "Enable automatic storage scaling"
  type        = bool
  default     = true
}

variable "max_storage_gb" {
  description = "Maximum storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "high_availability" {
  description = "Enable multi-AZ/regional deployment"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "app"
}

variable "database_user" {
  description = "Master username"
  type        = string
  default     = "app"
}

variable "password" {
  description = "Master password (generated if null)"
  type        = string
  default     = null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Secret Management
# -----------------------------------------------------------------------------
variable "create_secret" {
  description = "Create cloud-native secret with credentials"
  type        = bool
  default     = true
}

variable "secret_name" {
  description = "Name for the created secret"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Protection & Tags
# -----------------------------------------------------------------------------
variable "deletion_protection" {
  description = "Prevent accidental deletion"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags/labels"
  type        = map(string)
  default     = {}
}
