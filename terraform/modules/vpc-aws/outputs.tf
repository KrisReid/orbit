# =============================================================================
# AWS VPC Module - Outputs
# =============================================================================

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.private[*].cidr_block
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "db_subnet_group_name" {
  description = "The name of the database subnet group"
  value       = var.create_database_subnet_group ? aws_db_subnet_group.main[0].name : null
}

output "db_subnet_group_arn" {
  description = "The ARN of the database subnet group"
  value       = var.create_database_subnet_group ? aws_db_subnet_group.main[0].arn : null
}
