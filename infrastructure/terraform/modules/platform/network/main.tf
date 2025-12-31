# =============================================================================
# Platform Network Module
# =============================================================================
# Cloud-agnostic facade that routes to provider-specific implementations.
# =============================================================================

# -----------------------------------------------------------------------------
# AWS VPC Implementation
# -----------------------------------------------------------------------------
module "aws" {
  source = "../../network/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  name         = var.name
  region       = var.region
  vpc_cidr     = var.vpc_cidr
  az_count     = var.availability_zone_count
  cluster_name = var.kubernetes_cluster_name

  enable_nat                   = var.enable_nat
  single_nat_gateway           = var.single_nat
  create_database_subnet_group = var.enable_database_subnets
  enable_vpc_endpoints         = try(var.aws_config.enable_vpc_endpoints, true)

  tags = var.tags
}

# -----------------------------------------------------------------------------
# GCP VPC Implementation
# -----------------------------------------------------------------------------
module "gcp" {
  source = "../../network/gcp"
  count  = var.cloud_provider == "gcp" ? 1 : 0

  name       = var.name
  project_id = var.gcp_config.project_id
  region     = var.region

  # GCP uses a different CIDR strategy - subnet CIDR derived from vpc_cidr
  subnet_cidr   = cidrsubnet(var.vpc_cidr, 4, 0)  # e.g., 10.0.0.0/20 from 10.0.0.0/16
  pods_cidr     = var.gcp_config.pods_cidr
  services_cidr = var.gcp_config.services_cidr

  enable_nat              = var.enable_nat
  enable_private_services = var.enable_database_subnets && var.gcp_config.enable_private_services
}
