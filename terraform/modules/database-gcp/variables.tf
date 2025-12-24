# =============================================================================
# Cloud SQL PostgreSQL Module - Variables
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

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Machine type for the instance"
  type        = string
  default     = "db-f1-micro"
}

variable "availability_type" {
  description = "Availability type (REGIONAL or ZONAL)"
  type        = string
  default     = "REGIONAL"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Disk type (PD_SSD or PD_HDD)"
  type        = string
  default     = "PD_SSD"
}

variable "disk_autoresize" {
  description = "Enable automatic disk resize"
  type        = bool
  default     = true
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
    name = string
    cidr = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "orbit"
}

variable "database_user" {
  description = "Database user name"
  type        = string
  default     = "orbit"
}

variable "password" {
  description = "Database password (auto-generated if null)"
  type        = string
  default     = null
  sensitive   = true
}

variable "database_flags" {
  description = "Database flags to set"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
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
  description = "Start time for daily backup (HH:MM format)"
  type        = string
  default     = "03:00"
}

variable "backup_location" {
  description = "Location for storing backups"
  type        = string
  default     = null
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Number of days to retain transaction logs"
  type        = number
  default     = 7
}

variable "retained_backups" {
  description = "Number of backups to retain"
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# Maintenance Window
# -----------------------------------------------------------------------------
variable "maintenance_window_day" {
  description = "Day of week for maintenance (1=Monday, 7=Sunday)"
  type        = number
  default     = 7
}

variable "maintenance_window_hour" {
  description = "Hour of day for maintenance (0-23)"
  type        = number
  default     = 3
}

variable "maintenance_update_track" {
  description = "Maintenance update track (stable, canary)"
  type        = string
  default     = "stable"
}

# -----------------------------------------------------------------------------
# Query Insights
# -----------------------------------------------------------------------------
variable "query_insights_enabled" {
  description = "Enable Query Insights"
  type        = bool
  default     = true
}

variable "query_plans_per_minute" {
  description = "Number of query plans to sample per minute"
  type        = number
  default     = 5
}

variable "query_string_length" {
  description = "Maximum length of query strings"
  type        = number
  default     = 1024
}

variable "record_application_tags" {
  description = "Record application tags"
  type        = bool
  default     = true
}

variable "record_client_address" {
  description = "Record client address"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Secret Management
# -----------------------------------------------------------------------------
variable "create_secret" {
  description = "Create Secret Manager secret for password"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Labels & Protection
# -----------------------------------------------------------------------------
variable "labels" {
  description = "Labels to apply to the instance"
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}
