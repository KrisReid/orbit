# =============================================================================
# RDS PostgreSQL Module - Outputs
# =============================================================================

output "instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.main.id
}

output "instance_arn" {
  description = "The RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "instance_endpoint" {
  description = "The RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "instance_address" {
  description = "The RDS instance address (hostname)"
  value       = aws_db_instance.main.address
}

output "instance_port" {
  description = "The RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "The database name"
  value       = aws_db_instance.main.db_name
}

output "database_user" {
  description = "The master username"
  value       = aws_db_instance.main.username
}

output "database_password" {
  description = "The master password"
  value       = local.db_password
  sensitive   = true
}

output "security_group_id" {
  description = "The security group ID for the RDS instance"
  value       = aws_security_group.rds.id
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${aws_db_instance.main.username}:${local.db_password}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

output "secret_arn" {
  description = "The ARN of the Secrets Manager secret"
  value       = var.create_secret ? aws_secretsmanager_secret.db_password[0].arn : null
}
