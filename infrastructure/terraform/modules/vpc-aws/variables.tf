# =============================================================================
# AWS VPC Module - Variables
# =============================================================================

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3
}

variable "cluster_name" {
  description = "Name of the EKS cluster (for subnet tagging)"
  type        = string
}

variable "enable_nat" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway instead of one per AZ (cost saving)"
  type        = bool
  default     = false
}

variable "create_database_subnet_group" {
  description = "Create a DB subnet group for RDS"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for S3 and ECR (reduces NAT costs)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
