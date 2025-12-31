# =============================================================================
# Orbit Production Environment - Variables
# =============================================================================
# Cloud-agnostic variables for production deployment.
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
# Common Configuration
# -----------------------------------------------------------------------------
variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "orbit"
}

variable "region" {
  description = "Cloud region for deployment"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# -----------------------------------------------------------------------------
# AWS-Specific Configuration
# -----------------------------------------------------------------------------
variable "aws_config" {
  description = "AWS-specific configuration (required when cloud_provider = aws)"
  type = object({
    vpc_cidr                = optional(string, "10.0.0.0/16")
    availability_zone_count = optional(number, 3)
    enable_vpc_endpoints    = optional(bool, true)
    enable_nat_gateway      = optional(bool, true)
    single_nat_gateway      = optional(bool, false)
    
    # EKS Configuration
    kubernetes_version      = optional(string, "1.28")
    endpoint_private_access = optional(bool, true)
    endpoint_public_access  = optional(bool, true)
    public_access_cidrs     = optional(list(string), ["0.0.0.0/0"])
    node_groups = optional(map(object({
      instance_types  = optional(list(string), ["t3.medium"])
      capacity_type   = optional(string, "ON_DEMAND")
      disk_size       = optional(number, 50)
      desired_size    = optional(number, 2)
      min_size        = optional(number, 1)
      max_size        = optional(number, 4)
      labels          = optional(map(string), {})
    })), {
      default = {
        instance_types = ["t3.medium"]
        desired_size   = 2
        min_size       = 1
        max_size       = 4
      }
    })
  })
  default = null
}

# -----------------------------------------------------------------------------
# GCP-Specific Configuration
# -----------------------------------------------------------------------------
variable "gcp_config" {
  description = "GCP-specific configuration (required when cloud_provider = gcp)"
  type = object({
    project_id      = string
    vpc_subnet_cidr = optional(string, "10.0.0.0/20")
    pods_cidr       = optional(string, "10.16.0.0/14")
    services_cidr   = optional(string, "10.20.0.0/20")
    
    # GKE Configuration
    regional_cluster            = optional(bool, true)
    kubernetes_version_prefix   = optional(string, "1.28.")
    release_channel             = optional(string, "REGULAR")
    enable_private_nodes        = optional(bool, true)
    enable_private_endpoint     = optional(bool, false)
    master_ipv4_cidr_block      = optional(string, "172.16.0.0/28")
    master_authorized_networks  = optional(list(object({
      cidr_block   = string
      display_name = string
    })), [])
    node_pools = optional(map(object({
      machine_type       = optional(string, "e2-medium")
      initial_node_count = optional(number, 1)
      min_node_count     = optional(number, 1)
      max_node_count     = optional(number, 3)
      preemptible        = optional(bool, false)
      spot               = optional(bool, false)
      labels             = optional(map(string), {})
    })), {
      default = {
        machine_type       = "e2-medium"
        initial_node_count = 1
        min_node_count     = 1
        max_node_count     = 3
      }
    })
  })
  default = null
}

# -----------------------------------------------------------------------------
# Database Configuration (Cloud-Agnostic)
# -----------------------------------------------------------------------------
variable "database_instance_size" {
  description = "Normalized database size: small, medium, large, xlarge"
  type        = string
  default     = "small"
}

variable "database_storage_gb" {
  description = "Initial database storage in GB"
  type        = number
  default     = 20
}

variable "database_high_availability" {
  description = "Enable database high availability"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Name of the application database"
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

variable "database_backup_retention_days" {
  description = "Database backup retention in days"
  type        = number
  default     = 7
}

variable "database_deletion_protection" {
  description = "Enable database deletion protection"
  type        = bool
  default     = true
}

variable "database_skip_final_snapshot" {
  description = "Skip final snapshot when destroying database"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Kubernetes Addons Configuration
# -----------------------------------------------------------------------------
variable "enable_nginx_ingress" {
  description = "Enable NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "nginx_replica_count" {
  description = "Number of NGINX Ingress Controller replicas"
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
  description = "Email for Let's Encrypt registration"
  type        = string
  default     = ""
}

variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
  default     = true
}

variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# GitOps Configuration
# -----------------------------------------------------------------------------
variable "enable_gitops_bootstrap" {
  description = "Enable GitOps bootstrap (ClusterSecretStore + ExternalSecret)"
  type        = bool
  default     = true
}

variable "application_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "orbit"
}

variable "external_secrets_namespace" {
  description = "Namespace where External Secrets Operator is installed"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_service_account" {
  description = "Service account name for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "secret_refresh_interval" {
  description = "How often to sync secrets from cloud provider"
  type        = string
  default     = "1h"
}

# -----------------------------------------------------------------------------
# Cluster Configuration
# -----------------------------------------------------------------------------
variable "cluster_deletion_protection" {
  description = "Enable deletion protection for the Kubernetes cluster"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# GitHub Actions CI/CD Configuration
# -----------------------------------------------------------------------------
variable "enable_github_actions_cicd" {
  description = "Enable GitHub Actions CI/CD with Workload Identity Federation"
  type        = bool
  default     = false
}

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo' for Workload Identity Federation"
  type        = string
  default     = ""
}

variable "github_actions_service_account_roles" {
  description = "IAM roles to grant to the GitHub Actions service account (GCP only)"
  type        = list(string)
  default     = [
    "roles/container.developer",
    "roles/artifactregistry.writer"
  ]
}

# -----------------------------------------------------------------------------
# Tags/Labels
# -----------------------------------------------------------------------------
variable "tags" {
  description = "Tags/labels to apply to all resources"
  type        = map(string)
  default     = {}
}
