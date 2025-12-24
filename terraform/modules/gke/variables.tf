# =============================================================================
# GKE Cluster Module - Variables
# =============================================================================

variable "name" {
  description = "Name of the GKE cluster"
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

variable "regional" {
  description = "Create a regional cluster (true) or zonal cluster (false)"
  type        = bool
  default     = true
}

variable "network" {
  description = "VPC network self_link"
  type        = string
}

variable "subnetwork" {
  description = "VPC subnetwork self_link"
  type        = string
}

variable "pods_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
}

variable "services_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
}

variable "kubernetes_version_prefix" {
  description = "Kubernetes version prefix (e.g., '1.28.')"
  type        = string
  default     = "1.28."
}

variable "release_channel" {
  description = "GKE release channel (UNSPECIFIED, RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

# -----------------------------------------------------------------------------
# Private Cluster
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# Addons
# -----------------------------------------------------------------------------
variable "enable_http_load_balancing" {
  description = "Enable HTTP load balancing addon"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling addon"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable network policy addon"
  type        = bool
  default     = true
}

variable "enable_gce_pd_csi_driver" {
  description = "Enable GCE Persistent Disk CSI driver"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Monitoring & Logging
# -----------------------------------------------------------------------------
variable "logging_enabled_components" {
  description = "List of logging components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS", "WORKLOADS"]
}

variable "monitoring_enabled_components" {
  description = "List of monitoring components to enable"
  type        = list(string)
  default     = ["SYSTEM_COMPONENTS"]
}

variable "enable_managed_prometheus" {
  description = "Enable managed Prometheus"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Security
# -----------------------------------------------------------------------------
variable "enable_shielded_nodes" {
  description = "Enable shielded nodes"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Maintenance
# -----------------------------------------------------------------------------
variable "maintenance_start_time" {
  description = "Start time for daily maintenance window (UTC)"
  type        = string
  default     = "03:00"
}

# -----------------------------------------------------------------------------
# Node Pools
# -----------------------------------------------------------------------------
variable "node_pools" {
  description = "Map of node pool configurations"
  type = map(object({
    initial_node_count         = optional(number, 1)
    min_node_count             = optional(number, 1)
    max_node_count             = optional(number, 3)
    enable_autoscaling         = optional(bool, true)
    location_policy            = optional(string, "BALANCED")
    machine_type               = optional(string, "e2-medium")
    disk_size_gb               = optional(number, 100)
    disk_type                  = optional(string, "pd-standard")
    image_type                 = optional(string, "COS_CONTAINERD")
    oauth_scopes               = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    labels                     = optional(map(string), {})
    tags                       = optional(list(string), [])
    auto_repair                = optional(bool, true)
    auto_upgrade               = optional(bool, true)
    max_surge                  = optional(number, 1)
    max_unavailable            = optional(number, 0)
    preemptible                = optional(bool, false)
    spot                       = optional(bool, false)
    enable_secure_boot         = optional(bool, true)
    enable_integrity_monitoring = optional(bool, true)
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

# -----------------------------------------------------------------------------
# Labels & Metadata
# -----------------------------------------------------------------------------
variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}
