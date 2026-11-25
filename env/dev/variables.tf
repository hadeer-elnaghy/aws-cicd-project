
variable "deployment_region" {
  description = "AWS deployment region"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "network_name" {
  description = "VPC name"
  type        = string
}

variable "network_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "public_network_ranges" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_network_ranges" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "zone_names" {
  description = "Availability zones"
  type        = list(string)
}

variable "repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "node_machine_types" {
  description = "EKS worker node instance types"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_count" {
  description = "Desired worker node count"
  type        = number
  default     = 2
}

variable "node_min_count" {
  description = "Minimum worker node count"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum worker node count"
  type        = number
  default     = 3
}

variable "eks_user_arn" {
  description = "IAM user ARN allowed to access EKS"
  type        = string
}

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
