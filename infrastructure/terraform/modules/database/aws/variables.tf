# =============================================================================
# AWS RDS PostgreSQL Module - Variables
# =============================================================================

variable "name" {
  description = "Name of the RDS instance"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  type        = string
}

# -----------------------------------------------------------------------------
# Engine Configuration
# -----------------------------------------------------------------------------
variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "parameter_group_family" {
  description = "Parameter group family"
  type        = string
  default     = "postgres15"
}

variable "parameters" {
  description = "Database parameters to set"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Storage Configuration
# -----------------------------------------------------------------------------
variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling in GB (0 disables autoscaling)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type: gp2, gp3, io1"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
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
# Network & Security
# -----------------------------------------------------------------------------
variable "publicly_accessible" {
  description = "Enable public accessibility"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Enable multi-AZ deployment"
  type        = bool
  default     = false
}

variable "allowed_security_groups" {
  description = "Security group IDs allowed to connect"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Backup & Maintenance
# -----------------------------------------------------------------------------
variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "delete_automated_backups" {
  description = "Delete automated backups on deletion"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Monitoring
# -----------------------------------------------------------------------------
variable "enabled_cloudwatch_logs_exports" {
  description = "CloudWatch log exports"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval (0 to disable)"
  type        = number
  default     = 0
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Secret Management
# -----------------------------------------------------------------------------
variable "create_secret" {
  description = "Create Secrets Manager secret with credentials"
  type        = bool
  default     = true
}

variable "secret_name" {
  description = "Name for the Secrets Manager secret"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Protection & Tags
# -----------------------------------------------------------------------------
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
