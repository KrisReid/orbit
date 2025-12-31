# =============================================================================
# Platform Database Module
# =============================================================================
# Cloud-agnostic facade that routes to provider-specific implementations.
# =============================================================================

locals {
  # Instance size mappings per provider
  instance_sizes = {
    aws = {
      small  = "db.t3.micro"
      medium = "db.t3.small"
      large  = "db.r6g.large"
      xlarge = "db.r6g.xlarge"
    }
    gcp = {
      small  = "db-f1-micro"
      medium = "db-g1-small"
      large  = "db-custom-2-7680"
      xlarge = "db-custom-4-15360"
    }
  }

  # PostgreSQL version mappings
  engine_versions = {
    aws = var.engine_version
    gcp = "POSTGRES_${var.engine_version}"
  }

  # Resolved values
  resolved_instance_type = local.instance_sizes[var.cloud_provider][var.instance_size]
  resolved_engine        = local.engine_versions[var.cloud_provider]
  secret_name            = coalesce(var.secret_name, "${var.name}-credentials")
}

# -----------------------------------------------------------------------------
# AWS RDS Implementation
# -----------------------------------------------------------------------------
module "aws" {
  source = "../../database/aws"
  count  = var.cloud_provider == "aws" ? 1 : 0

  name                 = var.name
  vpc_id               = var.aws_config.vpc_id
  db_subnet_group_name = var.aws_config.db_subnet_group_name

  engine_version = local.resolved_engine
  instance_class = local.resolved_instance_type

  allocated_storage     = var.storage_gb
  max_allocated_storage = var.storage_autoscaling ? var.max_storage_gb : var.storage_gb

  database_name = var.database_name
  database_user = var.database_user
  password      = var.password

  multi_az                = var.high_availability
  backup_retention_period = var.backup_retention_days
  skip_final_snapshot     = var.skip_final_snapshot

  allowed_security_groups = var.aws_config.allowed_security_groups
  allowed_cidr_blocks     = var.allowed_cidr_blocks

  performance_insights_enabled = var.aws_config.performance_insights_enabled
  monitoring_interval          = var.aws_config.monitoring_interval

  create_secret = var.create_secret
  secret_name   = local.secret_name

  deletion_protection = var.deletion_protection
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# GCP Cloud SQL Implementation
# -----------------------------------------------------------------------------
module "gcp" {
  source = "../../database/gcp"
  count  = var.cloud_provider == "gcp" ? 1 : 0

  name            = var.name
  project_id      = var.gcp_config.project_id
  region          = var.region
  private_network = var.gcp_config.private_network

  database_version = local.resolved_engine
  tier             = local.resolved_instance_type

  disk_size       = var.storage_gb
  disk_autoresize = var.storage_autoscaling

  database_name = var.database_name
  database_user = var.database_user
  password      = var.password

  availability_type     = var.high_availability ? "REGIONAL" : "ZONAL"
  backup_retention_days = var.backup_retention_days

  insights_enabled = var.gcp_config.insights_enabled

  create_secret = var.create_secret
  secret_name   = local.secret_name

  deletion_protection = var.deletion_protection
  labels              = var.tags
}
