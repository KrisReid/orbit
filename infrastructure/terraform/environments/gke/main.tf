# =============================================================================
# Orbit GKE Environment
# =============================================================================
# Complete infrastructure and application deployment for Google Kubernetes Engine.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc-gcp"

  name       = var.project_name
  project_id = var.project_id
  region     = var.region

  subnet_cidr   = var.vpc_subnet_cidr
  pods_cidr     = var.vpc_pods_cidr
  services_cidr = var.vpc_services_cidr

  enable_nat              = var.enable_private_nodes
  enable_private_services = true
}

# -----------------------------------------------------------------------------
# GKE Cluster
# -----------------------------------------------------------------------------
module "gke" {
  source = "../../modules/gke"

  name       = "${var.project_name}-cluster"
  project_id = var.project_id
  region     = var.region
  regional   = var.regional_cluster

  network             = module.vpc.network_self_link
  subnetwork          = module.vpc.subnet_self_link
  pods_range_name     = module.vpc.pods_range_name
  services_range_name = module.vpc.services_range_name

  enable_private_nodes    = var.enable_private_nodes
  enable_private_endpoint = var.enable_private_endpoint
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block

  master_authorized_networks = var.master_authorized_networks

  kubernetes_version_prefix = var.kubernetes_version_prefix
  release_channel           = var.release_channel

  node_pools           = var.node_pools
  node_service_account = var.node_service_account

  enable_network_policy = var.enable_network_policy

  labels = var.labels

  deletion_protection = var.deletion_protection

  depends_on = [module.vpc]
}

# -----------------------------------------------------------------------------
# Cloud SQL Database
# -----------------------------------------------------------------------------
module "database" {
  source = "../../modules/database-gcp"

  name       = "${var.project_name}-db"
  project_id = var.project_id
  region     = var.region

  database_version  = var.database_version
  tier              = var.database_tier
  availability_type = var.database_availability_type
  disk_size         = var.database_disk_size

  private_network  = module.vpc.network_id
  enable_public_ip = false

  database_name = var.database_name
  database_user = var.database_user
  password      = var.database_password

  backup_enabled         = var.database_backup_enabled
  point_in_time_recovery = var.database_point_in_time_recovery

  labels = var.labels

  deletion_protection = var.deletion_protection

  depends_on = [module.vpc]
}

# -----------------------------------------------------------------------------
# Kubernetes Addons
# -----------------------------------------------------------------------------
module "kubernetes_addons" {
  source = "../../modules/kubernetes-addons"

  enable_nginx_ingress = var.enable_nginx_ingress
  nginx_replica_count  = var.nginx_replica_count

  enable_cert_manager        = var.enable_cert_manager
  create_letsencrypt_issuers = var.create_letsencrypt_issuers
  letsencrypt_email          = var.letsencrypt_email

  depends_on = [module.gke]
}

# -----------------------------------------------------------------------------
# Note: Orbit Application Deployment
# -----------------------------------------------------------------------------
# The Orbit application is deployed via ArgoCD (GitOps), not Terraform.
# See infrastructure/argocd/ for application deployment configuration.
#
# This Terraform configuration provisions:
# - VPC networking
# - GKE cluster
# - Cloud SQL database
# - Kubernetes addons (ingress-nginx, cert-manager)
#
# ArgoCD deploys:
# - Orbit Helm chart (backend, frontend, ingress)
#
# Database connection info is available via outputs for ArgoCD configuration.
# -----------------------------------------------------------------------------
