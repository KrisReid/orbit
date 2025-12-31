# =============================================================================
# Kubernetes Addons Module - Variables
# =============================================================================
# Cloud-agnostic Kubernetes addons: NGINX, cert-manager, ArgoCD, ESO
# =============================================================================

# -----------------------------------------------------------------------------
# Helm Configuration
# -----------------------------------------------------------------------------
variable "helm_timeout" {
  description = "Helm release timeout in seconds"
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
  default     = "4.8.3"
}

variable "nginx_replica_count" {
  description = "Number of NGINX Ingress Controller replicas"
  type        = number
  default     = 2
}

variable "nginx_service_type" {
  description = "Service type for NGINX Ingress Controller"
  type        = string
  default     = "LoadBalancer"
}

variable "nginx_service_annotations" {
  description = "Annotations for NGINX service (cloud-specific load balancer config)"
  type        = map(string)
  default     = {}
}

variable "nginx_config" {
  description = "NGINX ConfigMap settings"
  type        = map(string)
  default     = {}
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
  description = "Minimum number of NGINX replicas for autoscaling"
  type        = number
  default     = 2
}

variable "nginx_max_replicas" {
  description = "Maximum number of NGINX replicas for autoscaling"
  type        = number
  default     = 10
}

variable "nginx_target_cpu_utilization" {
  description = "Target CPU utilization for NGINX autoscaling"
  type        = number
  default     = 80
}

variable "nginx_extra_values" {
  description = "Extra Helm values for NGINX Ingress Controller (merged with base values)"
  type        = any
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

variable "cert_manager_extra_values" {
  description = "Extra Helm values for cert-manager (merged with base values)"
  type        = any
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

# -----------------------------------------------------------------------------
# ArgoCD Configuration
# -----------------------------------------------------------------------------
variable "enable_argocd" {
  description = "Enable ArgoCD"
  type        = bool
  default     = false
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "5.51.1"
}

variable "argocd_server_replicas" {
  description = "Number of ArgoCD server replicas"
  type        = number
  default     = 1
}

variable "argocd_extra_values" {
  description = "Extra Helm values for ArgoCD (merged with base values)"
  type        = any
  default     = {}
}

# -----------------------------------------------------------------------------
# External Secrets Operator
# -----------------------------------------------------------------------------
variable "enable_external_secrets" {
  description = "Enable External Secrets Operator"
  type        = bool
  default     = false
}

variable "external_secrets_namespace" {
  description = "Namespace for External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "external_secrets_chart_version" {
  description = "External Secrets Operator Helm chart version"
  type        = string
  default     = "0.9.9"
}

variable "external_secrets_service_account_annotations" {
  description = "Annotations for ESO service account (for IRSA/Workload Identity)"
  type        = map(string)
  default     = {}
}

variable "external_secrets_extra_values" {
  description = "Extra Helm values for External Secrets Operator (merged with base values)"
  type        = any
  default     = {}
}
