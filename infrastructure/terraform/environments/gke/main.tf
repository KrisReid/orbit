# =============================================================================
# Orbit GKE Environment
# =============================================================================
# Complete infrastructure deployment for Google Kubernetes Engine.
#
# This Terraform configuration provisions:
# - VPC networking with private Google access
# - GKE cluster with node pools
# - Cloud SQL PostgreSQL database
# - Kubernetes addons (nginx-ingress, cert-manager, ArgoCD, External Secrets)
# - GitOps bootstrap (ClusterSecretStore, ExternalSecret, application namespace)
#
# After `terraform apply`:
# 1. Configure kubectl with the output command
# 2. Apply ArgoCD Application: kustomize build infrastructure/argocd/overlays/production | kubectl apply -f -
# =============================================================================

# -----------------------------------------------------------------------------
# Project Services
# -----------------------------------------------------------------------------
resource "google_project_service" "main" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com"
  ])

  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = false
  disable_on_destroy         = false
}

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

  depends_on = [google_project_service.main]
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

  # Store password in GCP Secret Manager for External Secrets
  create_secret = true

  backup_enabled         = var.database_backup_enabled
  point_in_time_recovery = var.database_point_in_time_recovery

  labels = var.labels

  deletion_protection = var.deletion_protection

  depends_on = [module.vpc]
}

# -----------------------------------------------------------------------------
# GCP Service Account for External Secrets (created here to avoid cycles)
# -----------------------------------------------------------------------------
resource "google_service_account" "external_secrets" {
  count = var.enable_external_secrets ? 1 : 0

  account_id   = "${var.project_name}-eso"
  display_name = "External Secrets Operator for ${var.project_name}"
  project      = var.project_id

  depends_on = [google_project_service.main]
}

# Grant Secret Manager access to the service account
resource "google_project_iam_member" "external_secrets_secretmanager" {
  count = var.enable_external_secrets ? 1 : 0

  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.external_secrets[0].email}"
}

# Workload Identity binding - allows K8s SA to impersonate GCP SA
resource "google_service_account_iam_member" "external_secrets_workload_identity" {
  count = var.enable_external_secrets ? 1 : 0

  service_account_id = google_service_account.external_secrets[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.external_secrets_namespace}/${var.external_secrets_service_account}]"
}

# -----------------------------------------------------------------------------
# Kubernetes Addons
# -----------------------------------------------------------------------------
module "kubernetes_addons" {
  source = "../../modules/kubernetes-addons"

  # NGINX Ingress
  enable_nginx_ingress = var.enable_nginx_ingress
  nginx_replica_count  = var.nginx_replica_count

  # cert-manager
  enable_cert_manager        = var.enable_cert_manager
  create_letsencrypt_issuers = var.create_letsencrypt_issuers
  letsencrypt_email          = var.letsencrypt_email

  # ArgoCD
  enable_argocd = var.enable_argocd

  # External Secrets Operator
  enable_external_secrets = var.enable_external_secrets
  external_secrets_service_account_annotations = var.enable_external_secrets ? {
    "iam.gke.io/gcp-service-account" = google_service_account.external_secrets[0].email
  } : {}

  depends_on = [module.gke, google_service_account.external_secrets]
}

# -----------------------------------------------------------------------------
# GitOps Bootstrap (ClusterSecretStore + ExternalSecret + Namespace)
# -----------------------------------------------------------------------------
module "gitops" {
  source = "../../modules/gitops-gcp"
  count  = var.enable_gitops_bootstrap ? 1 : 0

  project_id = var.project_id

  cluster_name     = module.gke.cluster_name
  cluster_location = var.regional_cluster ? var.region : "${var.region}-a"

  # External Secrets configuration
  external_secrets_namespace       = var.external_secrets_namespace
  external_secrets_service_account = var.external_secrets_service_account
  external_secrets_ready           = module.kubernetes_addons
  secret_refresh_interval          = var.secret_refresh_interval

  # Database configuration (from Cloud SQL module)
  database_host      = module.database.private_ip_address
  database_name      = module.database.database_name
  database_user      = module.database.database_user
  database_secret_id = module.database.secret_id

  # Application configuration
  application_namespace = var.application_namespace

  depends_on = [module.kubernetes_addons, module.database]
}
