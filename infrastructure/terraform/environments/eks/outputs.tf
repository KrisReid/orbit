# =============================================================================
# Orbit EKS Environment - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Outputs
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

# -----------------------------------------------------------------------------
# EKS Cluster Outputs
# -----------------------------------------------------------------------------
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the EKS cluster"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------
output "database_endpoint" {
  description = "The RDS instance endpoint"
  value       = module.database.instance_endpoint
}

output "database_address" {
  description = "The RDS instance address"
  value       = module.database.instance_address
}

output "database_host" {
  description = "Database host for Orbit application configuration"
  value       = module.database.instance_address
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
  description = "Name of the ClusterSecretStore for AWS Secrets Manager"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].secret_store_name : null
}

output "gitops_kubernetes_secret_name" {
  description = "Name of the Kubernetes secret containing database credentials"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].kubernetes_secret_name : null
}

output "gitops_external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].external_secrets_role_arn : null
}

output "application_namespace" {
  description = "Namespace where the Orbit application will be deployed"
  value       = var.enable_gitops_bootstrap ? module.gitops[0].application_namespace : var.application_namespace
}

# -----------------------------------------------------------------------------
# Quick Start Instructions
# -----------------------------------------------------------------------------
output "next_steps" {
  description = "Instructions for accessing your deployment"
  value       = <<-EOT
    
    ✅ Infrastructure deployed successfully!
    
    Next steps to deploy the Orbit application:
    
    1. Configure kubectl:
       aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}
    
    2. Deploy the ArgoCD Application (GitOps):
       kustomize build infrastructure/argocd/overlays/production | kubectl apply -f -
    
    3. Check ArgoCD Application status:
       kubectl get applications -n argocd
    
    4. Get ArgoCD admin password:
       kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    
    5. Access ArgoCD UI:
       kubectl port-forward svc/argocd-server -n argocd 8080:443
       Then open: https://localhost:8080
    
    Database credentials are automatically synced from AWS Secrets Manager
    to Kubernetes via External Secrets Operator.
    
  EOT
}
