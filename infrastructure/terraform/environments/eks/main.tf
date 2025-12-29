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

  # ArgoCD
  enable_argocd = var.enable_argocd

  # External Secrets Operator
  enable_external_secrets = var.enable_external_secrets
  external_secrets_service_account_annotations = var.enable_external_secrets ? {
    "eks.amazonaws.com/role-arn" = module.gitops[0].external_secrets_role_arn
  } : {}

  depends_on = [module.eks]
}

# -----------------------------------------------------------------------------
# GitOps Bootstrap (External Secrets + ArgoCD Application)
# -----------------------------------------------------------------------------
module "gitops" {
  source = "../../modules/gitops-aws"
  count  = var.enable_gitops_bootstrap ? 1 : 0

  region       = var.region
  cluster_name = module.eks.cluster_name

  # IRSA configuration
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  # External Secrets configuration
  external_secrets_namespace       = var.external_secrets_namespace
  external_secrets_service_account = var.external_secrets_service_account
  external_secrets_ready           = module.kubernetes_addons
  secret_refresh_interval          = var.secret_refresh_interval

  # Database configuration (from RDS module)
  database_host        = module.database.instance_address
  database_name        = var.database_name
  database_user        = var.database_user
  database_secret_name = module.database.secret_name

  # Application configuration
  application_namespace = var.application_namespace

  # ArgoCD configuration
  argocd_namespace          = var.argocd_namespace
  deploy_argocd_application = var.deploy_argocd_application
  enable_argocd_finalizer   = var.enable_argocd_finalizer

  # Git repository configuration
  git_repo_url        = var.git_repo_url
  git_target_revision = var.git_target_revision
  helm_chart_path     = var.helm_chart_path
  helm_value_files    = var.helm_value_files

  # Container images
  backend_image_repository  = var.backend_image_repository
  backend_image_tag         = var.backend_image_tag
  frontend_image_repository = var.frontend_image_repository
  frontend_image_tag        = var.frontend_image_tag

  # Ingress configuration
  enable_ingress = var.enable_app_ingress
  ingress_host   = var.ingress_host
  enable_tls     = var.enable_tls
  cluster_issuer = var.cluster_issuer

  # Sync configuration
  enable_auto_sync    = var.enable_auto_sync
  auto_sync_prune     = var.auto_sync_prune
  auto_sync_self_heal = var.auto_sync_self_heal

  tags = var.tags

  depends_on = [module.kubernetes_addons, module.database]
}
