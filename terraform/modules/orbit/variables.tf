# =============================================================================
# Orbit Application Module - Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Helm Release Configuration
# -----------------------------------------------------------------------------
variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "orbit"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "orbit"
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = true
}

variable "chart_path" {
  description = "Path to the Helm chart"
  type        = string
  default     = "../../helm/orbit"
}

variable "chart_version" {
  description = "Helm chart version"
  type        = string
  default     = null
}

variable "helm_timeout" {
  description = "Timeout for Helm operations in seconds"
  type        = number
  default     = 600
}

variable "wait_for_deployment" {
  description = "Wait for the deployment to complete"
  type        = bool
  default     = true
}

variable "depends_on_resources" {
  description = "Resources that this release depends on"
  type        = list(any)
  default     = []
}

# -----------------------------------------------------------------------------
# Global Settings
# -----------------------------------------------------------------------------
variable "image_pull_secrets" {
  description = "Image pull secrets"
  type        = list(string)
  default     = []
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = ""
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

# -----------------------------------------------------------------------------
# Backend Configuration
# -----------------------------------------------------------------------------
variable "backend_replica_count" {
  description = "Number of backend replicas"
  type        = number
  default     = 1
}

variable "backend_image_repository" {
  description = "Backend image repository"
  type        = string
  default     = "ghcr.io/your-org/orbit-backend"
}

variable "backend_image_tag" {
  description = "Backend image tag"
  type        = string
  default     = ""
}

variable "backend_resources" {
  description = "Backend resource requests and limits"
  type = object({
    requests = optional(object({
      memory = optional(string, "256Mi")
      cpu    = optional(string, "100m")
    }), {})
    limits = optional(object({
      memory = optional(string, "512Mi")
      cpu    = optional(string, "500m")
    }), {})
  })
  default = {}
}

variable "debug_mode" {
  description = "Enable debug mode"
  type        = bool
  default     = false
}

variable "task_id_prefix" {
  description = "Prefix for task IDs"
  type        = string
  default     = "ORBIT"
}

variable "backend_env" {
  description = "Additional backend environment variables"
  type        = map(string)
  default     = {}
}

variable "backend_autoscaling_enabled" {
  description = "Enable backend autoscaling"
  type        = bool
  default     = false
}

variable "backend_min_replicas" {
  description = "Minimum backend replicas for autoscaling"
  type        = number
  default     = 1
}

variable "backend_max_replicas" {
  description = "Maximum backend replicas for autoscaling"
  type        = number
  default     = 5
}

variable "backend_target_cpu" {
  description = "Target CPU utilization for backend autoscaling"
  type        = number
  default     = 80
}

# -----------------------------------------------------------------------------
# Frontend Configuration
# -----------------------------------------------------------------------------
variable "frontend_replica_count" {
  description = "Number of frontend replicas"
  type        = number
  default     = 1
}

variable "frontend_image_repository" {
  description = "Frontend image repository"
  type        = string
  default     = "ghcr.io/your-org/orbit-frontend"
}

variable "frontend_image_tag" {
  description = "Frontend image tag"
  type        = string
  default     = ""
}

variable "frontend_resources" {
  description = "Frontend resource requests and limits"
  type = object({
    requests = optional(object({
      memory = optional(string, "64Mi")
      cpu    = optional(string, "50m")
    }), {})
    limits = optional(object({
      memory = optional(string, "128Mi")
      cpu    = optional(string, "200m")
    }), {})
  })
  default = {}
}

variable "frontend_autoscaling_enabled" {
  description = "Enable frontend autoscaling"
  type        = bool
  default     = false
}

variable "frontend_min_replicas" {
  description = "Minimum frontend replicas for autoscaling"
  type        = number
  default     = 1
}

variable "frontend_max_replicas" {
  description = "Maximum frontend replicas for autoscaling"
  type        = number
  default     = 3
}

variable "frontend_target_cpu" {
  description = "Target CPU utilization for frontend autoscaling"
  type        = number
  default     = 80
}

# -----------------------------------------------------------------------------
# Ingress Configuration
# -----------------------------------------------------------------------------
variable "ingress_enabled" {
  description = "Enable ingress"
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_host" {
  description = "Ingress hostname"
  type        = string
  default     = "orbit.example.com"
}

variable "ingress_annotations" {
  description = "Ingress annotations"
  type        = map(string)
  default     = {}
}

variable "ingress_tls_enabled" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = false
}

variable "ingress_tls_secret_name" {
  description = "TLS secret name for ingress"
  type        = string
  default     = "orbit-tls"
}

variable "cert_manager_issuer" {
  description = "cert-manager ClusterIssuer to use"
  type        = string
  default     = "letsencrypt-prod"
}

# -----------------------------------------------------------------------------
# Database Configuration
# -----------------------------------------------------------------------------
variable "use_external_database" {
  description = "Use external database instead of PostgreSQL subchart"
  type        = bool
  default     = false
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
  description = "Database password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "external_database_host" {
  description = "External database host"
  type        = string
  default     = ""
}

variable "external_database_port" {
  description = "External database port"
  type        = number
  default     = 5432
}

variable "external_database_secret" {
  description = "Existing secret for external database credentials"
  type        = string
  default     = ""
}

variable "external_database_secret_key" {
  description = "Key in existing secret for database password"
  type        = string
  default     = "password"
}

variable "postgresql_storage_size" {
  description = "Storage size for PostgreSQL PVC"
  type        = string
  default     = "8Gi"
}

variable "postgresql_resources" {
  description = "PostgreSQL resource requests and limits"
  type = object({
    requests = optional(object({
      memory = optional(string, "256Mi")
      cpu    = optional(string, "100m")
    }), {})
    limits = optional(object({
      memory = optional(string, "512Mi")
      cpu    = optional(string, "500m")
    }), {})
  })
  default = {}
}

# -----------------------------------------------------------------------------
# Service Account
# -----------------------------------------------------------------------------
variable "create_service_account" {
  description = "Create a service account"
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Service account name"
  type        = string
  default     = ""
}

variable "service_account_annotations" {
  description = "Service account annotations"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Security & Availability
# -----------------------------------------------------------------------------
variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = false
}

variable "enable_pdb" {
  description = "Enable Pod Disruption Budget"
  type        = bool
  default     = false
}

variable "pdb_min_available" {
  description = "Minimum available pods for PDB"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Extra Values
# -----------------------------------------------------------------------------
variable "extra_set_values" {
  description = "Extra Helm set values"
  type        = map(string)
  default     = {}
}

variable "extra_sensitive_values" {
  description = "Extra Helm sensitive set values"
  type        = map(string)
  default     = {}
  sensitive   = true
}
