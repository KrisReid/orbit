# =============================================================================
# Kubernetes Addons Module - Outputs
# =============================================================================

output "nginx_ingress_namespace" {
  description = "The namespace where NGINX Ingress Controller is installed"
  value       = var.enable_nginx_ingress ? var.nginx_namespace : null
}

output "nginx_ingress_class" {
  description = "The ingress class name for NGINX Ingress Controller"
  value       = var.enable_nginx_ingress ? "nginx" : null
}

output "cert_manager_namespace" {
  description = "The namespace where cert-manager is installed"
  value       = var.enable_cert_manager ? var.cert_manager_namespace : null
}

output "letsencrypt_staging_issuer" {
  description = "The name of the Let's Encrypt staging ClusterIssuer"
  value       = var.enable_cert_manager && var.create_letsencrypt_issuers ? "letsencrypt-staging" : null
}

output "letsencrypt_prod_issuer" {
  description = "The name of the Let's Encrypt production ClusterIssuer"
  value       = var.enable_cert_manager && var.create_letsencrypt_issuers ? "letsencrypt-prod" : null
}

output "argocd_namespace" {
  description = "The namespace where ArgoCD is installed"
  value       = var.enable_argocd ? var.argocd_namespace : null
}

output "external_secrets_namespace" {
  description = "The namespace where External Secrets Operator is installed"
  value       = var.enable_external_secrets ? var.external_secrets_namespace : null
}

# Dependency marker for other modules
output "ready" {
  description = "Marker to indicate addons are installed"
  value       = true
  depends_on = [
    helm_release.nginx_ingress,
    helm_release.cert_manager,
    helm_release.argocd,
    helm_release.external_secrets,
  ]
}
