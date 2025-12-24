# =============================================================================
# Kubernetes Addons Module - Variables
# =============================================================================

variable "helm_timeout" {
  description = "Timeout for Helm releases in seconds"
  type        = number
  default     = 600
}

# -----------------------------------------------------------------------------
# NGINX Ingress Controller
# -----------------------------------------------------------------------------
variable "enable_nginx_ingress" {
  description = "Enable NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "nginx_namespace" {
  description = "Namespace for NGINX Ingress Controller"
  type        = string
  default     = "ingress-nginx"
}

variable "nginx_chart_version" {
  description = "NGINX Ingress Controller Helm chart version"
  type        = string
  default     = "4.9.0"
}

variable "nginx_replica_count" {
  description = "Number of NGINX Ingress Controller replicas"
  type        = number
  default     = 2
}

variable "nginx_resources" {
  description = "Resource requests and limits for NGINX Ingress Controller"
  type = object({
    requests = optional(object({
      cpu    = optional(string, "100m")
      memory = optional(string, "128Mi")
    }), {})
    limits = optional(object({
      cpu    = optional(string, "500m")
      memory = optional(string, "512Mi")
    }), {})
  })
  default = {}
}

variable "nginx_service_type" {
  description = "Service type for NGINX Ingress Controller"
  type        = string
  default     = "LoadBalancer"
}

variable "nginx_service_annotations" {
  description = "Annotations for NGINX Ingress Controller service"
  type        = map(string)
  default     = {}
}

variable "nginx_config" {
  description = "NGINX configuration map"
  type        = map(string)
  default = {
    "proxy-body-size"      = "50m"
    "proxy-read-timeout"   = "60"
    "proxy-send-timeout"   = "60"
    "use-forwarded-headers" = "true"
  }
}

variable "enable_nginx_metrics" {
  description = "Enable Prometheus metrics for NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "enable_nginx_service_monitor" {
  description = "Enable ServiceMonitor for NGINX Ingress Controller"
  type        = bool
  default     = false
}

variable "enable_nginx_admission_webhooks" {
  description = "Enable admission webhooks for NGINX Ingress Controller"
  type        = bool
  default     = true
}

variable "enable_nginx_autoscaling" {
  description = "Enable autoscaling for NGINX Ingress Controller"
  type        = bool
  default     = false
}

variable "nginx_min_replicas" {
  description = "Minimum number of replicas for NGINX autoscaling"
  type        = number
  default     = 2
}

variable "nginx_max_replicas" {
  description = "Maximum number of replicas for NGINX autoscaling"
  type        = number
  default     = 10
}

variable "nginx_target_cpu_utilization" {
  description = "Target CPU utilization for NGINX autoscaling"
  type        = number
  default     = 80
}

variable "nginx_extra_values" {
  description = "Extra Helm values for NGINX Ingress Controller"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# cert-manager
# -----------------------------------------------------------------------------
variable "enable_cert_manager" {
  description = "Enable cert-manager"
  type        = bool
  default     = true
}

variable "cert_manager_namespace" {
  description = "Namespace for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_chart_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.13.3"
}

variable "cert_manager_replica_count" {
  description = "Number of cert-manager replicas"
  type        = number
  default     = 1
}

variable "cert_manager_resources" {
  description = "Resource requests and limits for cert-manager"
  type = object({
    requests = optional(object({
      cpu    = optional(string, "50m")
      memory = optional(string, "64Mi")
    }), {})
    limits = optional(object({
      cpu    = optional(string, "200m")
      memory = optional(string, "256Mi")
    }), {})
  })
  default = {}
}

variable "enable_cert_manager_metrics" {
  description = "Enable Prometheus metrics for cert-manager"
  type        = bool
  default     = true
}

variable "enable_cert_manager_service_monitor" {
  description = "Enable ServiceMonitor for cert-manager"
  type        = bool
  default     = false
}

variable "cert_manager_webhook_replica_count" {
  description = "Number of cert-manager webhook replicas"
  type        = number
  default     = 1
}

variable "cert_manager_cainjector_replica_count" {
  description = "Number of cert-manager cainjector replicas"
  type        = number
  default     = 1
}

variable "cert_manager_extra_values" {
  description = "Extra Helm values for cert-manager"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Let's Encrypt Configuration
# -----------------------------------------------------------------------------
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
