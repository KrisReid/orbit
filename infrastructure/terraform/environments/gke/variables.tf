# =============================================================================
# Orbit GKE Environment - Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Required Variables
# -----------------------------------------------------------------------------
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

# -----------------------------------------------------------------------------
# VPC Configuration
# -----------------------------------------------------------------------------
variable "vpc_subnet_cidr" {
  description = "CIDR range for the VPC subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "vpc_pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.16.0.0/14"
}

variable "vpc_services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.20.0.0/20"
}

# -----------------------------------------------------------------------------
# GKE Cluster Configuration
# -----------------------------------------------------------------------------
variable "regional_cluster" {
  description = "Create a regional cluster (true) or zonal cluster (false)"
  type        = bool
  default     = true
}

variable "enable_private_nodes" {
  description = "Enable private nodes (no public IPs)"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint (master not accessible publicly)"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the master's private IP range"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "List of master authorized networks"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "kubernetes_version_prefix" {
  description = "Kubernetes version prefix"
  type        = string
  default     = "1.28."
}

variable "release_channel" {
  description = "GKE release channel"
  type        = string
  default     = "REGULAR"
}

variable "node_pools" {
  description = "Node pool configurations"
  type = map(object({
    initial_node_count = optional(number, 1)
    min_node_count     = optional(number, 1)
    max_node_count     = optional(number, 3)
    enable_autoscaling = optional(bool, true)
    machine_type       = optional(string, "e2-medium")
    disk_size_gb       = optional(number, 100)
    disk_type          = optional(string, "pd-standard")
    preemptible        = optional(bool, false)
    spot               = optional(bool, false)
    labels             = optional(map(string), {})
    tags               = optional(list(string), [])
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {
    default = {
      initial_node_count = 1
      min_node_count     = 1
      max_node_count     = 3
      machine_type       = "e2-medium"
    }
  }
}

variable "node_service_account" {
  description = "Service account for nodes"
  type        = string
  default     = null
}

variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "database_tier" {
  description = "Cloud SQL machine type"
  type        = string
  default     = "db-f1-micro"
}

variable "database_availability_type" {
  description = "Database availability type (REGIONAL or ZONAL)"
  type        = string
  default     = "REGIONAL"
}

variable "database_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "orbit"
}

variable "database_user" {
  description = "Database username"
  type        = string
  default     = "orbit"
}

variable "database_password" {
  description = "Database password (auto-generated if not set)"
  type        = string
  default     = null
  sensitive   = true
}

variable "database_backup_enabled" {
  description = "Enable database backups"
  type        = bool
  default     = true
}

variable "database_point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Kubernetes Addons
# -----------------------------------------------------------------------------
variable "enable_nginx_ingress" {
  description = "Enable NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "nginx_replica_count" {
  description = "NGINX Ingress Controller replica count"
  type        = number
  default     = 2
}

variable "enable_cert_manager" {
  description = "Enable cert-manager"
  type        = bool
  default     = true
}

variable "create_letsencrypt_issuers" {
  description = "Create Let's Encrypt ClusterIssuers"
  type        = bool
  default     = true
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Labels & Protection
# -----------------------------------------------------------------------------
variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}
