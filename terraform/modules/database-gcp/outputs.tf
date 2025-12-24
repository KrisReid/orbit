# =============================================================================
# Cloud SQL PostgreSQL Module - Outputs
# =============================================================================

output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "The connection name of the instance (for Cloud SQL Proxy)"
  value       = google_sql_database_instance.main.connection_name
}

output "private_ip_address" {
  description = "The private IP address of the instance"
  value       = google_sql_database_instance.main.private_ip_address
}

output "public_ip_address" {
  description = "The public IP address of the instance"
  value       = var.enable_public_ip ? google_sql_database_instance.main.public_ip_address : null
}

output "database_name" {
  description = "The name of the database"
  value       = google_sql_database.main.name
}

output "database_user" {
  description = "The database user"
  value       = google_sql_user.main.name
}

output "database_password" {
  description = "The database password"
  value       = local.db_password
  sensitive   = true
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${google_sql_user.main.name}:${local.db_password}@${google_sql_database_instance.main.private_ip_address}:5432/${google_sql_database.main.name}"
  sensitive   = true
}

output "secret_id" {
  description = "The Secret Manager secret ID containing the password"
  value       = var.create_secret ? google_secret_manager_secret.db_password[0].secret_id : null
}
