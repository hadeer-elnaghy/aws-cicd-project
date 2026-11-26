
variable "database_name" {
  description = "RDS instance identifier"
  type        = string
}

variable "initial_database_name" {
  description = "Initial PostgreSQL database name"
  type        = string
}

variable "database_username" {
  description = "PostgreSQL master username"
  type        = string
}

variable "database_password" {
  description = "PostgreSQL master password"
  type        = string
  sensitive   = true
}

variable "database_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for RDS"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  type        = string
}
