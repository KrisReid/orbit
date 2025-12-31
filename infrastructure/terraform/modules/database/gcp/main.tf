# =============================================================================
# GCP Cloud SQL PostgreSQL Module
# =============================================================================
# Creates a Cloud SQL PostgreSQL instance for production workloads.
# =============================================================================

# -----------------------------------------------------------------------------
# Password Generation
# -----------------------------------------------------------------------------
resource "random_password" "db_password" {
  count   = var.password == null ? 1 : 0
  length  = 24
  special = false
}

locals {
  db_password = coalesce(var.password, try(random_password.db_password[0].result, null))
  secret_name = coalesce(var.secret_name, "${var.name}-credentials")
}

# -----------------------------------------------------------------------------
# Cloud SQL Instance
# -----------------------------------------------------------------------------
resource "google_sql_database_instance" "main" {
  name                = var.name
  project             = var.project_id
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier                  = var.tier
    availability_type     = var.availability_type
    disk_size             = var.disk_size
    disk_type             = var.disk_type
    disk_autoresize       = var.disk_autoresize
    disk_autoresize_limit = var.disk_autoresize_limit

    # IP Configuration
    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network
      ssl_mode        = var.require_ssl ? "ENCRYPTED_ONLY" : "ALLOW_UNENCRYPTED_AND_ENCRYPTED"

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    # Backup Configuration
    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      transaction_log_retention_days = var.backup_retention_days
      point_in_time_recovery_enabled = var.point_in_time_recovery

      backup_retention_settings {
        retained_backups = var.backup_retention_days
        retention_unit   = "COUNT"
      }
    }

    # Maintenance Window
    maintenance_window {
      day          = var.maintenance_day
      hour         = var.maintenance_hour
      update_track = "stable"
    }

    # Database Flags
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Query Insights
    dynamic "insights_config" {
      for_each = var.insights_enabled ? [1] : []
      content {
        query_insights_enabled  = true
        query_string_length     = 1024
        record_application_tags = true
        record_client_address   = true
      }
    }

    user_labels = var.labels
  }

  lifecycle {
    ignore_changes = [
      settings[0].disk_size,
    ]
  }
}

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------
resource "google_sql_database" "main" {
  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.main.name
}

# -----------------------------------------------------------------------------
# Database User
# -----------------------------------------------------------------------------
resource "google_sql_user" "main" {
  name     = var.database_user
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = local.db_password
}

# -----------------------------------------------------------------------------
# Secret Manager Secret
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret" "db_credentials" {
  count     = var.create_secret ? 1 : 0
  project   = var.project_id
  secret_id = local.secret_name

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_credentials" {
  count  = var.create_secret ? 1 : 0
  secret = google_secret_manager_secret.db_credentials[0].id
  secret_data = jsonencode({
    username          = google_sql_user.main.name
    password          = local.db_password
    host              = google_sql_database_instance.main.private_ip_address
    port              = 5432
    database          = google_sql_database.main.name
    connection_name   = google_sql_database_instance.main.connection_name
    connection_string = "postgresql://${google_sql_user.main.name}:${local.db_password}@${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.main.name}"
  })
}
