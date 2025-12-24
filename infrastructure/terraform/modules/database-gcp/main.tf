# =============================================================================
# Cloud SQL PostgreSQL Module
# =============================================================================
# Creates a Cloud SQL PostgreSQL instance for production workloads.
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
# Cloud SQL Instance
# -----------------------------------------------------------------------------
resource "google_sql_database_instance" "main" {
  name                = var.name
  project             = var.project_id
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type
    disk_autoresize   = var.disk_autoresize

    # IP Configuration
    ip_configuration {
      ipv4_enabled                                  = var.enable_public_ip
      private_network                               = var.private_network
      ssl_mode                                      = var.require_ssl ? "ENCRYPTED_ONLY" : "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      enable_private_path_for_google_cloud_services = true

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    # Backup configuration
    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      location                       = var.backup_location
      point_in_time_recovery_enabled = var.point_in_time_recovery
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_update_track
    }

    # Insights
    insights_config {
      query_insights_enabled  = var.query_insights_enabled
      query_plans_per_minute  = var.query_plans_per_minute
      query_string_length     = var.query_string_length
      record_application_tags = var.record_application_tags
      record_client_address   = var.record_client_address
    }

    # Database flags
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    user_labels = var.labels
  }

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------
resource "google_sql_database" "main" {
  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.main.name

  depends_on = [google_sql_database_instance.main]
}

# -----------------------------------------------------------------------------
# Database User
# -----------------------------------------------------------------------------
resource "google_sql_user" "main" {
  name     = var.database_user
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = local.db_password

  depends_on = [google_sql_database_instance.main]
}

# -----------------------------------------------------------------------------
# Secret Manager (optional)
# -----------------------------------------------------------------------------
resource "google_secret_manager_secret" "db_password" {
  count     = var.create_secret ? 1 : 0
  project   = var.project_id
  secret_id = "${var.name}-db-password"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "db_password" {
  count       = var.create_secret ? 1 : 0
  secret      = google_secret_manager_secret.db_password[0].id
  secret_data = local.db_password
}
