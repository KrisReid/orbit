# =============================================================================
# Orbit EKS Environment
# =============================================================================
# Complete infrastructure and application deployment for Amazon Elastic Kubernetes Service.
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc-aws"

  name         = var.project_name
  region       = var.region
  vpc_cidr     = var.vpc_cidr
  az_count     = var.availability_zone_count
  cluster_name = "${var.project_name}-cluster"

  enable_nat                   = var.enable_nat_gateway
  single_nat_gateway           = var.single_nat_gateway
  create_database_subnet_group = true
  enable_vpc_endpoints         = var.enable_vpc_endpoints

  tags = var.tags
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  name       = "${var.project_name}-cluster"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  kubernetes_version = var.kubernetes_version

  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  public_access_cidrs     = var.public_access_cidrs

  enabled_cluster_log_types = var.enabled_cluster_log_types

  enable_vpc_cni_addon    = true
  enable_coredns_addon    = true
  enable_kube_proxy_addon = true
  enable_ebs_csi_addon    = true

  node_groups = var.node_groups

  tags = var.tags

  depends_on = [module.vpc]
}

# -----------------------------------------------------------------------------
# RDS Database
# -----------------------------------------------------------------------------
module "database" {
  source = "../../modules/database-aws"

  name                 = "${var.project_name}-db"
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.db_subnet_group_name

  engine_version = var.database_engine_version
  instance_class = var.database_instance_class
  multi_az       = var.database_multi_az

  allocated_storage     = var.database_allocated_storage
  max_allocated_storage = var.database_max_allocated_storage

  database_name = var.database_name
  database_user = var.database_user
  password      = var.database_password

  allowed_security_groups = [module.eks.node_security_group_id]

  backup_retention_period = var.database_backup_retention_period
  skip_final_snapshot     = var.database_skip_final_snapshot

  performance_insights_enabled = var.database_performance_insights_enabled

  deletion_protection = var.deletion_protection

  tags = var.tags

  depends_on = [module.vpc, module.eks]
}

# -----------------------------------------------------------------------------
# Kubernetes Addons
# -----------------------------------------------------------------------------
module "kubernetes_addons" {
  source = "../../modules/kubernetes-addons"

  enable_nginx_ingress = var.enable_nginx_ingress
  nginx_replica_count  = var.nginx_replica_count

  # AWS-specific annotations for NLB
  nginx_service_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-type"            = "nlb"
    "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
  }

  enable_cert_manager        = var.enable_cert_manager
  create_letsencrypt_issuers = var.create_letsencrypt_issuers
  letsencrypt_email          = var.letsencrypt_email

  depends_on = [module.eks]
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
  external_database_host = module.database.instance_address
  database_name          = var.database_name
  database_user          = var.database_user
  database_password      = module.database.database_password

  # Service Account with IRSA
  create_service_account      = true
  service_account_annotations = var.irsa_enabled ? {
    "eks.amazonaws.com/role-arn" = var.irsa_role_arn
  } : {}

  depends_on = [
    module.eks,
    module.database,
    module.kubernetes_addons
  ]
}
