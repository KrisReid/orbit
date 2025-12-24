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
# Orbit Application
# -----------------------------------------------------------------------------
module "orbit" {
  source = "../../modules/orbit"

  release_name = var.project_name
  namespace    = var.orbit_namespace
  chart_path   = var.orbit_chart_path

  # Backend
  backend_replica_count    = var.backend_replica_count
  backend_image_repository = var.backend_image_repository
  backend_image_tag        = var.backend_image_tag
  backend_resources        = var.backend_resources

  # Frontend
  frontend_replica_count    = var.frontend_replica_count
  frontend_image_repository = var.frontend_image_repository
  frontend_image_tag        = var.frontend_image_tag
  frontend_resources        = var.frontend_resources

  # Ingress
  ingress_enabled         = var.ingress_enabled
  ingress_class_name      = "nginx"
  ingress_host            = var.ingress_host
  ingress_tls_enabled     = var.ingress_tls_enabled
  ingress_tls_secret_name = var.ingress_tls_secret_name
  cert_manager_issuer     = var.cert_manager_issuer

  # External Database
  use_external_database  = true
  external_database_host = module.database.private_ip_address
  database_name          = var.database_name
  database_user          = var.database_user
  database_password      = module.database.database_password

  # Service Account with Workload Identity
  create_service_account      = true
  service_account_annotations = {
    "iam.gke.io/gcp-service-account" = var.workload_identity_sa
  }

  depends_on = [
    module.gke,
    module.database,
    module.kubernetes_addons
  ]
}
