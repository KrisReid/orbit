# =============================================================================
# Orbit EKS Environment
# =============================================================================
# Complete infrastructure deployment for Amazon Elastic Kubernetes Service.
#
# This Terraform configuration provisions:
# - VPC networking with public/private subnets
# - EKS cluster with managed node groups
# - RDS PostgreSQL database
# - Kubernetes addons (nginx-ingress, cert-manager, ArgoCD, External Secrets)
# - GitOps bootstrap (ClusterSecretStore, ExternalSecret, application namespace)
#
# After `terraform apply`:
# 1. Configure kubectl with the output command
# 2. Apply ArgoCD Application: kustomize build infrastructure/argocd/overlays/production | kubectl apply -f -
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
  external_secrets_service_account_annotations = var.enable_external_secrets && var.enable_gitops_bootstrap ? {
    "eks.amazonaws.com/role-arn" = module.gitops[0].external_secrets_role_arn
  } : {}

  depends_on = [module.eks]
}

# -----------------------------------------------------------------------------
# GitOps Bootstrap (ClusterSecretStore + ExternalSecret + Namespace)
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

  tags = var.tags

  depends_on = [module.kubernetes_addons, module.database]
}
