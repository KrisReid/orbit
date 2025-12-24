# =============================================================================
# RDS PostgreSQL Module
# =============================================================================
# Creates an RDS PostgreSQL instance for production workloads.
# =============================================================================

# -----------------------------------------------------------------------------
# Random password for database
# -----------------------------------------------------------------------------
resource "random_password" "db_password" {
  count   = var.password == null ? 1 : 0
  length  = 24
  special = false
}

locals {
  db_password = var.password != null ? var.password : random_password.db_password[0].result
}

# -----------------------------------------------------------------------------
# Security Group for RDS
# -----------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_groups
    content {
      description     = "PostgreSQL from allowed security group"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      description = "PostgreSQL from allowed CIDR blocks"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-rds-sg"
  })
}

# -----------------------------------------------------------------------------
# RDS Parameter Group
# -----------------------------------------------------------------------------
resource "aws_db_parameter_group" "main" {
  name        = "${var.name}-pg15-params"
  family      = var.parameter_group_family
  description = "Parameter group for ${var.name}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# RDS Instance
# -----------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier = var.name

  # Engine
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  parameter_group_name = aws_db_parameter_group.main.name

  # Storage
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  # Database
  db_name  = var.database_name
  username = var.database_user
  password = local.db_password
  port     = 5432

  # Network
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = true
  delete_automated_backups  = var.delete_automated_backups
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"
  skip_final_snapshot       = var.skip_final_snapshot

  # Monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Security
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Upgrade
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately

  # Protection
  deletion_protection = var.deletion_protection

  tags = var.tags

  depends_on = [aws_db_parameter_group.main]
}

# -----------------------------------------------------------------------------
# IAM Role for Enhanced Monitoring
# -----------------------------------------------------------------------------
resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -----------------------------------------------------------------------------
# Secrets Manager (optional)
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "db_password" {
  count       = var.create_secret ? 1 : 0
  name        = "${var.name}-db-password"
  description = "Database password for ${var.name}"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count     = var.create_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.db_password[0].id
  secret_string = jsonencode({
    username = var.database_user
    password = local.db_password
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    database = var.database_name
  })
}
