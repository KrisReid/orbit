# =============================================================================
# GCP Cloud SQL PostgreSQL Module - Variables
# =============================================================================

variable "name" {
  description = "Name of the Cloud SQL instance"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

# -----------------------------------------------------------------------------
# Engine Configuration
# -----------------------------------------------------------------------------
variable "database_version" {
  description = "PostgreSQL version (e.g., POSTGRES_15)"
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Machine type for the instance"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "Availability type: REGIONAL or ZONAL"
  type        = string
  default     = "ZONAL"
}

# -----------------------------------------------------------------------------
# Storage Configuration
# -----------------------------------------------------------------------------
variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Disk type: PD_SSD or PD_HDD"
  type        = string
  default     = "PD_SSD"
}

variable "disk_autoresize" {
  description = "Enable automatic disk resize"
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "Maximum disk size for autoresize (0 = unlimited)"
  type        = number
  default     = 0
}

# -----------------------------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------------------------
variable "private_network" {
  description = "VPC network self_link for private IP"
  type        = string
}

variable "enable_public_ip" {
  description = "Enable public IP address"
  type        = bool
  default     = false
}

variable "require_ssl" {
  description = "Require SSL connections"
  type        = bool
  default     = true
}

variable "authorized_networks" {
  description = "List of authorized networks for public access"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
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
# Backup Configuration
# -----------------------------------------------------------------------------
variable "backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Start time for daily backups (HH:MM format)"
  type        = string
  default     = "03:00"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Maintenance
# -----------------------------------------------------------------------------
variable "maintenance_day" {
  description = "Day of week for maintenance (1-7, Monday=1)"
  type        = number
  default     = 1
}

variable "maintenance_hour" {
  description = "Hour of day for maintenance (0-23)"
  type        = number
  default     = 4
}

# -----------------------------------------------------------------------------
# Database Flags
# -----------------------------------------------------------------------------
variable "database_flags" {
  description = "Database flags to set"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Insights
# -----------------------------------------------------------------------------
variable "insights_enabled" {
  description = "Enable Query Insights"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Secret Management
# -----------------------------------------------------------------------------
variable "create_secret" {
  description = "Create Secret Manager secret with credentials"
  type        = bool
  default     = true
}

variable "secret_name" {
  description = "Name for the Secret Manager secret"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Protection & Labels
# -----------------------------------------------------------------------------
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}
