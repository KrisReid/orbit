# =============================================================================
# Orbit GKE Environment - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = module.vpc.network_name
}

output "vpc_subnet_name" {
  description = "The name of the VPC subnet"
  value       = module.vpc.subnet_name
}

# -----------------------------------------------------------------------------
# GKE Cluster Outputs
# -----------------------------------------------------------------------------
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = module.gke.kubeconfig_command
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------
output "database_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = module.database.instance_name
}

output "database_connection_name" {
  description = "The connection name for Cloud SQL Proxy"
  value       = module.database.instance_connection_name
}

output "database_private_ip" {
  description = "The private IP address of the database"
  value       = module.database.private_ip_address
}

# -----------------------------------------------------------------------------
# Database Connection Info (for ArgoCD/Helm values)
# -----------------------------------------------------------------------------
# These outputs provide the database connection information needed
# for ArgoCD to configure the Orbit Helm chart with external database settings.
#
# Example usage in ArgoCD values:
#   externalDatabase:
#     enabled: true
#     host: <database_host output>
#     port: 5432
#     database: <database_name output>
#     username: <database_user output>
#     existingSecret: "orbit-db-secret"
#     existingSecretPasswordKey: "password"
# -----------------------------------------------------------------------------
output "database_host" {
  description = "Database host for Orbit application configuration"
  value       = module.database.private_ip_address
}

output "database_name" {
  description = "Database name for Orbit application"
  value       = var.database_name
}

output "database_user" {
  description = "Database username for Orbit application"
  value       = var.database_user
}

output "database_password" {
  description = "Database password (store in Kubernetes secret for ArgoCD)"
  value       = module.database.database_password
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Kubernetes Addons Outputs
# -----------------------------------------------------------------------------
output "nginx_ingress_namespace" {
  description = "The namespace where NGINX Ingress Controller is installed"
  value       = module.kubernetes_addons.nginx_ingress_namespace
}

output "cert_manager_namespace" {
  description = "The namespace where cert-manager is installed"
  value       = module.kubernetes_addons.cert_manager_namespace
}

output "external_secrets_namespace" {
  description = "The namespace where External Secrets Operator is installed"
  value       = module.kubernetes_addons.external_secrets_namespace
}

# -----------------------------------------------------------------------------
# GitOps Outputs
# -----------------------------------------------------------------------------
output "gitops_secret_store_name" {
  description = "Name of the ClusterSecretStore for GCP Secret Manager"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].secret_store_name : null
}

output "gitops_kubernetes_secret_name" {
  description = "Name of the Kubernetes secret containing database credentials"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].kubernetes_secret_name : null
}

output "gitops_argocd_application_name" {
  description = "Name of the ArgoCD Application"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].argocd_application_name : null
}

output "gitops_external_secrets_gcp_sa" {
  description = "GCP service account for External Secrets Operator"
  value       = var.enable_external_secrets ? google_service_account.external_secrets[0].email : null
}

output "gitops_workload_identity_binding" {
  description = "Workload Identity binding for External Secrets"
  value       = var.enable_external_secrets ? "serviceAccount:${var.project_id}.svc.id.goog[${var.external_secrets_namespace}/${var.external_secrets_service_account}]" : null
}

# -----------------------------------------------------------------------------
# Quick Start Instructions
# -----------------------------------------------------------------------------
locals {
  gitops_enabled_message = <<-EOT
    
    ✅ Infrastructure deployed successfully!
    
    Your Orbit application is being deployed via ArgoCD.
    
    1. Configure kubectl:
       ${module.gke.kubeconfig_command}
    
    2. Check ArgoCD Application status:
       kubectl get applications -n ${var.argocd_namespace}
    
    3. Get ArgoCD admin password:
       kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    
    4. Access ArgoCD UI:
       kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:443
       Then open: https://localhost:8080
    
    5. Your application will be available at:
       https://${var.ingress_host}
    
    Database credentials are automatically synced from GCP Secret Manager
    to Kubernetes via External Secrets Operator.
    
  EOT

  gitops_disabled_message = "GitOps bootstrap not enabled. Set enable_gitops_bootstrap = true to deploy the application."
}

output "next_steps" {
  description = "Instructions for accessing your deployment"
  value       = var.enable_gitops_bootstrap ? local.gitops_enabled_message : local.gitops_disabled_message
}
