# =============================================================================
# GCP VPC Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all resources"
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

variable "subnet_cidr" {
  description = "CIDR range for the primary subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.16.0.0/14"
}

variable "services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.20.0.0/20"
}

variable "enable_nat" {
  description = "Enable Cloud NAT for private GKE nodes"
  type        = bool
  default     = true
}

variable "enable_private_services" {
  description = "Enable private services connection for Cloud SQL"
  type        = bool
  default     = true
}
