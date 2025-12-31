# =============================================================================
# EKS Cluster Module - Variables
# =============================================================================

variable "name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
}

# -----------------------------------------------------------------------------
# Cluster Endpoint Access
# -----------------------------------------------------------------------------
variable "endpoint_private_access" {
  description = "Enable private API server endpoint access"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint access"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
variable "enabled_cluster_log_types" {
  description = "List of control plane log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# -----------------------------------------------------------------------------
# Addons
# -----------------------------------------------------------------------------
variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_addon" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Node Groups
# -----------------------------------------------------------------------------
variable "node_groups" {
  description = "Node group configurations"
  type = map(object({
    instance_types  = optional(list(string), ["t3.medium"])
    capacity_type   = optional(string, "ON_DEMAND")
    disk_size       = optional(number, 50)
    desired_size    = optional(number, 2)
    min_size        = optional(number, 1)
    max_size        = optional(number, 4)
    max_unavailable = optional(number, 1)
    labels          = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    tags = optional(map(string), {})
  }))
  default = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
  }
}

# -----------------------------------------------------------------------------
# Tags
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
