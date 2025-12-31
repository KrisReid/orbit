# =============================================================================
# EKS Cluster Module - Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster Outputs (Required by Interface Contract)
# -----------------------------------------------------------------------------
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the EKS cluster (base64 decoded)"
  value       = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${data.aws_region.current.id}"
}

# -----------------------------------------------------------------------------
# Authentication Outputs
# -----------------------------------------------------------------------------
output "cluster_auth_token" {
  description = "Auth token (null for AWS - uses exec plugin)"
  value       = null
  sensitive   = true
}

# -----------------------------------------------------------------------------
# OIDC / Workload Identity Outputs
# -----------------------------------------------------------------------------
output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC Provider"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# -----------------------------------------------------------------------------
# Security Outputs
# -----------------------------------------------------------------------------
output "cluster_security_group_id" {
  description = "The security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "node_security_group_id" {
  description = "The security group ID for EKS worker nodes"
  value       = aws_security_group.node.id
}

# -----------------------------------------------------------------------------
# Additional Outputs
# -----------------------------------------------------------------------------
output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = aws_eks_cluster.main.version
}

output "node_role_arn" {
  description = "The ARN of the IAM role used by node groups"
  value       = aws_iam_role.node.arn
}

# Data source for current region
data "aws_region" "current" {}
