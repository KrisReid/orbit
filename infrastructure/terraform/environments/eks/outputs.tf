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
