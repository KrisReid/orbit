# =============================================================================
# Orbit Production Environment
# =============================================================================
# Cloud-agnostic infrastructure deployment using platform abstraction modules.
#
# This configuration provisions:
# - VPC/Network (via platform/network)
# - Kubernetes cluster (EKS or GKE)
# - Managed PostgreSQL database (via platform/database)
# - Kubernetes addons (nginx-ingress, cert-manager, ArgoCD, ESO)
# - GitOps bootstrap (via platform/gitops)
#
# Usage:
#   cp terraform.tfvars.example terraform.tfvars
#   # Edit terraform.tfvars with your configuration
#   terraform init
#   terraform apply
# =============================================================================

locals {
  # Merged tags (lowercase for GCP compatibility)
  common_tags = merge(var.tags, {
    environment = var.environment
    project     = var.project_name
    managedby   = "terraform"
  })

  # Cluster name
  cluster_name = "${var.project_name}-cluster"

  # GKE cluster location
  gke_location = var.cloud_provider == "gcp" ? (
    try(var.gcp_config.regional_cluster, true) ? var.region : "${var.region}-a"
  ) : null
}

# -----------------------------------------------------------------------------
# GCP Project Services (GCP only)
# -----------------------------------------------------------------------------
resource "google_project_service" "main" {
  for_each = var.cloud_provider == "gcp" ? toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
  ]) : toset([])

  project                    = var.gcp_config.project_id
  service                    = each.key
  disable_dependent_services = false
  disable_on_destroy         = false
}

# -----------------------------------------------------------------------------
# Network (Platform Module)
# -----------------------------------------------------------------------------
module "network" {
  source = "../../modules/platform/network"

  cloud_provider = var.cloud_provider
  name           = var.project_name
  region         = var.region

  # Common configuration
  vpc_cidr                = var.cloud_provider == "aws" ? try(var.aws_config.vpc_cidr, "10.0.0.0/16") : "10.0.0.0/16"
  availability_zone_count = var.cloud_provider == "aws" ? try(var.aws_config.availability_zone_count, 3) : 3
  enable_nat              = var.cloud_provider == "aws" ? try(var.aws_config.enable_nat_gateway, true) : true
  single_nat              = var.cloud_provider == "aws" ? try(var.aws_config.single_nat_gateway, false) : false
  enable_database_subnets = true
  kubernetes_cluster_name = local.cluster_name

  # Provider-specific configuration
  aws_config = var.cloud_provider == "aws" ? {
    enable_vpc_endpoints = try(var.aws_config.enable_vpc_endpoints, true)
  } : null

  gcp_config = var.cloud_provider == "gcp" ? {
    project_id              = var.gcp_config.project_id
    pods_cidr               = try(var.gcp_config.pods_cidr, "10.16.0.0/14")
    services_cidr           = try(var.gcp_config.services_cidr, "10.20.0.0/20")
    enable_private_services = true
  } : null

  tags = local.common_tags

  depends_on = [google_project_service.main]
}

# -----------------------------------------------------------------------------
# Kubernetes Cluster (AWS - EKS)
# -----------------------------------------------------------------------------
module "kubernetes_aws" {
  source = "../../modules/kubernetes/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  name       = local.cluster_name
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  kubernetes_version      = try(var.aws_config.kubernetes_version, "1.28")
  endpoint_private_access = try(var.aws_config.endpoint_private_access, true)
  endpoint_public_access  = try(var.aws_config.endpoint_public_access, true)
  public_access_cidrs     = try(var.aws_config.public_access_cidrs, ["0.0.0.0/0"])

  node_groups = try(var.aws_config.node_groups, {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
  })

  tags = local.common_tags

  depends_on = [module.network]
}

# -----------------------------------------------------------------------------
# Kubernetes Cluster (GCP - GKE)
# -----------------------------------------------------------------------------
module "kubernetes_gcp" {
  source = "../../modules/kubernetes/gcp"
  count  = var.cloud_provider == "gcp" ? 1 : 0

  name       = local.cluster_name
  project_id = var.gcp_config.project_id
  region     = var.region
  regional   = try(var.gcp_config.regional_cluster, true)

  network             = module.network.vpc_self_link
  subnetwork          = module.network.subnet_self_link
  pods_range_name     = module.network.pods_range_name
  services_range_name = module.network.services_range_name

  kubernetes_version_prefix  = try(var.gcp_config.kubernetes_version_prefix, "1.28.")
  release_channel            = try(var.gcp_config.release_channel, "REGULAR")
  enable_private_nodes       = try(var.gcp_config.enable_private_nodes, true)
  enable_private_endpoint    = try(var.gcp_config.enable_private_endpoint, false)
  master_ipv4_cidr_block     = try(var.gcp_config.master_ipv4_cidr_block, "172.16.0.0/28")
  master_authorized_networks = try(var.gcp_config.master_authorized_networks, [])

  node_pools = try(var.gcp_config.node_pools, {
    default = {
      machine_type       = "e2-medium"
      initial_node_count = 1
      min_node_count     = 1
      max_node_count     = 3
    }
  })

  labels              = local.common_tags
  deletion_protection = var.cluster_deletion_protection

  depends_on = [module.network, google_project_service.main]
}

# -----------------------------------------------------------------------------
# Database (Platform Module)
# -----------------------------------------------------------------------------
module "database" {
  source = "../../modules/platform/database"

  cloud_provider = var.cloud_provider
  name           = "${var.project_name}-db"
  region         = var.region

  # Common configuration
  instance_size         = var.database_instance_size
  storage_gb            = var.database_storage_gb
  high_availability     = var.database_high_availability
  database_name         = var.database_name
  database_user         = var.database_user
  password              = var.database_password
  backup_retention_days = var.database_backup_retention_days
  deletion_protection   = var.database_deletion_protection
  skip_final_snapshot   = var.database_skip_final_snapshot

  # Provider-specific configuration
  aws_config = var.cloud_provider == "aws" ? {
    vpc_id                  = module.network.vpc_id
    db_subnet_group_name    = module.network.database_subnet_group_name
    allowed_security_groups = [module.kubernetes_aws[0].node_security_group_id]
  } : null

  gcp_config = var.cloud_provider == "gcp" ? {
    project_id      = var.gcp_config.project_id
    private_network = module.network.vpc_self_link
  } : null

  tags = local.common_tags

  depends_on = [module.network, module.kubernetes_aws, module.kubernetes_gcp]
}

# =============================================================================
# External Secrets IAM/SA (created here to avoid circular dependency)
# =============================================================================

# -----------------------------------------------------------------------------
# AWS: IAM Role for External Secrets (IRSA)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "external_secrets" {
  count = var.cloud_provider == "aws" && var.enable_gitops_bootstrap ? 1 : 0
  name  = "${local.cluster_name}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.kubernetes_aws[0].oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(module.kubernetes_aws[0].oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.external_secrets_namespace}:${var.external_secrets_service_account}"
          "${replace(module.kubernetes_aws[0].oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "external_secrets" {
  count = var.cloud_provider == "aws" && var.enable_gitops_bootstrap ? 1 : 0
  name  = "${local.cluster_name}-external-secrets-policy"
  role  = aws_iam_role.external_secrets[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# GCP: Service Account for External Secrets (Workload Identity)
# -----------------------------------------------------------------------------
resource "google_service_account" "external_secrets" {
  count        = var.cloud_provider == "gcp" && var.enable_gitops_bootstrap ? 1 : 0
  account_id   = "${var.project_name}-external-secrets"
  display_name = "External Secrets Operator for ${var.project_name}"
  project      = var.gcp_config.project_id
}

resource "google_project_iam_member" "external_secrets_secret_accessor" {
  count   = var.cloud_provider == "gcp" && var.enable_gitops_bootstrap ? 1 : 0
  project = var.gcp_config.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.external_secrets[0].email}"
}

resource "google_service_account_iam_member" "external_secrets_workload_identity" {
  count              = var.cloud_provider == "gcp" && var.enable_gitops_bootstrap ? 1 : 0
  service_account_id = google_service_account.external_secrets[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.gcp_config.project_id}.svc.id.goog[${var.external_secrets_namespace}/${var.external_secrets_service_account}]"
}

# =============================================================================
# GitHub Actions CI/CD IAM (Workload Identity Federation)
# =============================================================================

# -----------------------------------------------------------------------------
# GCP: Workload Identity Pool for GitHub Actions
# -----------------------------------------------------------------------------
resource "google_iam_workload_identity_pool" "github" {
  count                     = var.cloud_provider == "gcp" && var.enable_github_actions_cicd ? 1 : 0
  workload_identity_pool_id = "${var.project_name}-github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions CI/CD"
  project                   = var.gcp_config.project_id
}

resource "google_iam_workload_identity_pool_provider" "github" {
  count                              = var.cloud_provider == "gcp" && var.enable_github_actions_cicd ? 1 : 0
  workload_identity_pool_id          = google_iam_workload_identity_pool.github[0].workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  project                            = var.gcp_config.project_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = var.github_repository != "" ? "assertion.repository == '${var.github_repository}'" : null

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "github_actions" {
  count        = var.cloud_provider == "gcp" && var.enable_github_actions_cicd ? 1 : 0
  account_id   = "${var.project_name}-github-actions"
  display_name = "GitHub Actions CI/CD for ${var.project_name}"
  project      = var.gcp_config.project_id
}

resource "google_project_iam_member" "github_actions_roles" {
  for_each = var.cloud_provider == "gcp" && var.enable_github_actions_cicd ? toset(var.github_actions_service_account_roles) : toset([])
  project  = var.gcp_config.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.github_actions[0].email}"
}

resource "google_service_account_iam_member" "github_actions_workload_identity" {
  count              = var.cloud_provider == "gcp" && var.enable_github_actions_cicd && var.github_repository != "" ? 1 : 0
  service_account_id = google_service_account.github_actions[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github[0].name}/attribute.repository/${var.github_repository}"
}

# -----------------------------------------------------------------------------
# AWS: OIDC Provider for GitHub Actions
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {
  count = var.cloud_provider == "aws" && var.enable_github_actions_cicd ? 1 : 0
}

data "tls_certificate" "github_actions" {
  count = var.cloud_provider == "aws" && var.enable_github_actions_cicd ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count           = var.cloud_provider == "aws" && var.enable_github_actions_cicd ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions[0].certificates[0].sha1_fingerprint]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-github-actions-oidc"
  })
}

resource "aws_iam_role" "github_actions" {
  count = var.cloud_provider == "aws" && var.enable_github_actions_cicd ? 1 : 0
  name  = "${var.project_name}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_actions[0].arn
      }
      Condition = var.github_repository != "" ? {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
        }
      } : {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  count      = var.cloud_provider == "aws" && var.enable_github_actions_cicd ? 1 : 0
  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy" "github_actions_eks" {
  count = var.cloud_provider == "aws" && var.enable_github_actions_cicd ? 1 : 0
  name  = "${var.project_name}-github-actions-eks"
  role  = aws_iam_role.github_actions[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Kubernetes Addons
# -----------------------------------------------------------------------------
module "kubernetes_addons" {
  source = "../../modules/kubernetes-addons"

  # NGINX Ingress
  enable_nginx_ingress = var.enable_nginx_ingress
  nginx_replica_count  = var.nginx_replica_count

  # Cloud-specific load balancer annotations
  nginx_service_annotations = var.cloud_provider == "aws" ? {
    "service.beta.kubernetes.io/aws-load-balancer-type"            = "nlb"
    "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
  } : {}

  # cert-manager
  enable_cert_manager        = var.enable_cert_manager
  create_letsencrypt_issuers = var.create_letsencrypt_issuers
  letsencrypt_email          = var.letsencrypt_email

  # ArgoCD
  enable_argocd = var.enable_argocd

  # External Secrets Operator
  enable_external_secrets = var.enable_external_secrets
  external_secrets_service_account_annotations = var.enable_external_secrets && var.enable_gitops_bootstrap ? (
    var.cloud_provider == "aws" ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets[0].arn
    } : var.cloud_provider == "gcp" ? {
      "iam.gke.io/gcp-service-account" = google_service_account.external_secrets[0].email
    } : {}
  ) : {}

  depends_on = [
    module.kubernetes_aws,
    module.kubernetes_gcp,
    aws_iam_role.external_secrets,
    google_service_account.external_secrets
  ]
}

# -----------------------------------------------------------------------------
# GitOps Bootstrap (Platform Module)
# -----------------------------------------------------------------------------
module "gitops" {
  source = "../../modules/platform/gitops"
  count  = var.enable_gitops_bootstrap ? 1 : 0

  cloud_provider = var.cloud_provider
  cluster_name   = local.cluster_name
  region         = var.region

  # Application configuration
  application_namespace = var.application_namespace

  # External Secrets configuration
  external_secrets_namespace       = var.external_secrets_namespace
  external_secrets_service_account = var.external_secrets_service_account
  external_secrets_ready           = module.kubernetes_addons
  secret_refresh_interval          = var.secret_refresh_interval

  # Database configuration
  database_host      = module.database.host
  database_name      = module.database.database_name
  database_user      = module.database.database_user
  database_secret_id = module.database.secret_id

  # Provider-specific configuration (reserved for future use)
  aws_config = null

  gcp_config = var.cloud_provider == "gcp" ? {
    project_id       = var.gcp_config.project_id
    cluster_location = local.gke_location
  } : null

  tags = local.common_tags

  depends_on = [module.kubernetes_addons, module.database]
}
