# =============================================================================
# Orbit Production Environment - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "VPC/Network ID"
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.network.private_subnet_ids
}

# -----------------------------------------------------------------------------
# Kubernetes Cluster Outputs
# -----------------------------------------------------------------------------
output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = local.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value = coalesce(
    try(module.kubernetes_aws[0].cluster_endpoint, null),
    try(module.kubernetes_gcp[0].cluster_endpoint, null)
  )
  sensitive = true
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value = coalesce(
    try(module.kubernetes_aws[0].kubeconfig_command, null),
    try(module.kubernetes_gcp[0].kubeconfig_command, null)
  )
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------
output "database_host" {
  description = "Database hostname"
  value       = module.database.host
}

output "database_name" {
  description = "Database name"
  value       = module.database.database_name
}

output "database_user" {
  description = "Database username"
  value       = module.database.database_user
}

output "database_password" {
  description = "Database password"
  value       = module.database.database_password
  sensitive   = true
}

output "database_secret_id" {
  description = "Cloud secret ID containing database credentials"
  value       = module.database.secret_id
}

# -----------------------------------------------------------------------------
# Kubernetes Addons Outputs
# -----------------------------------------------------------------------------
output "nginx_ingress_namespace" {
  description = "NGINX Ingress Controller namespace"
  value       = module.kubernetes_addons.nginx_ingress_namespace
}

output "cert_manager_namespace" {
  description = "cert-manager namespace"
  value       = module.kubernetes_addons.cert_manager_namespace
}

output "external_secrets_namespace" {
  description = "External Secrets Operator namespace"
  value       = module.kubernetes_addons.external_secrets_namespace
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = module.kubernetes_addons.argocd_namespace
}

# -----------------------------------------------------------------------------
# GitOps Outputs
# -----------------------------------------------------------------------------
output "application_namespace" {
  description = "Application namespace"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].application_namespace : var.application_namespace
}

output "cluster_secret_store_name" {
  description = "Name of the ClusterSecretStore"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].cluster_secret_store_name : null
}

output "kubernetes_secret_name" {
  description = "Name of the Kubernetes secret containing database credentials"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].kubernetes_secret_name : null
}

# -----------------------------------------------------------------------------
# Provider-Specific Outputs
# -----------------------------------------------------------------------------
output "aws_outputs" {
  description = "AWS-specific outputs"
  value = var.cloud_provider == "aws" ? {
    oidc_provider_arn         = try(module.kubernetes_aws[0].oidc_provider_arn, null)
    node_security_group_id    = try(module.kubernetes_aws[0].node_security_group_id, null)
    external_secrets_role_arn = var.enable_gitops_bootstrap ? try(module.gitops[0].external_secrets_role_arn, null) : null
  } : null
}

output "gcp_outputs" {
  description = "GCP-specific outputs"
  value = var.cloud_provider == "gcp" ? {
    workload_identity_pool              = try(module.kubernetes_gcp[0].workload_identity_pool, null)
    external_secrets_service_account    = var.enable_gitops_bootstrap ? try(module.gitops[0].external_secrets_service_account_email, null) : null
  } : null
}

# -----------------------------------------------------------------------------
# GitHub Actions CI/CD Outputs
# -----------------------------------------------------------------------------
output "github_actions_workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions (use in GitHub Actions workflow)"
  value = var.enable_github_actions_cicd ? (
    var.cloud_provider == "gcp" ? try(google_iam_workload_identity_pool_provider.github[0].name, null) :
    var.cloud_provider == "aws" ? try(aws_iam_openid_connect_provider.github_actions[0].arn, null) :
    null
  ) : null
}

output "github_actions_service_account" {
  description = "Service Account/Role for GitHub Actions (use in GitHub Actions workflow)"
  value = var.enable_github_actions_cicd ? (
    var.cloud_provider == "gcp" ? try(google_service_account.github_actions[0].email, null) :
    var.cloud_provider == "aws" ? try(aws_iam_role.github_actions[0].arn, null) :
    null
  ) : null
}

# -----------------------------------------------------------------------------
# Next Steps
# -----------------------------------------------------------------------------
output "next_steps" {
  description = "Instructions for deploying the application"
  value       = <<-EOT
    
    ✅ Infrastructure deployed successfully!
    
  EOT
}
