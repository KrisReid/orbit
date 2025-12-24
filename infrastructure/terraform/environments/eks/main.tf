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
# Note: Orbit Application Deployment
# -----------------------------------------------------------------------------
# The Orbit application is deployed via ArgoCD (GitOps), not Terraform.
# See infrastructure/argocd/ for application deployment configuration.
#
# This Terraform configuration provisions:
# - VPC networking
# - EKS cluster
# - RDS database
# - Kubernetes addons (ingress-nginx, cert-manager)
#
# ArgoCD deploys:
# - Orbit Helm chart (backend, frontend, ingress)
#
# Database connection info is available via outputs for ArgoCD configuration.
# -----------------------------------------------------------------------------
