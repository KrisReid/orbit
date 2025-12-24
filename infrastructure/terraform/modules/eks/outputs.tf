# =============================================================================
# EKS Cluster Module - Outputs
# =============================================================================

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The base64 encoded certificate data for the cluster"
  value       = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes server version for the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "The security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "The security group ID attached to the EKS nodes"
  value       = aws_security_group.nodes.id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.main.arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC Provider"
  value       = aws_iam_openid_connect_provider.main.url
}

output "node_groups" {
  description = "Map of node group names to node group IDs"
  value       = { for k, v in aws_eks_node_group.main : k => v.id }
}

# Kubeconfig helper
output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.main.name} --region ${data.aws_caller_identity.current.id != "" ? "us-east-1" : "us-east-1"}"
}
