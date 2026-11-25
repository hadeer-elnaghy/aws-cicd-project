
output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "nat_gateway_id" {
  value = module.network.nat_gateway_id
}

output "ecr_repository_url" {
  value = module.container_registry.repository_url
}

output "eks_cluster_name" {
  value = module.kubernetes.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.kubernetes.cluster_endpoint
}

output "eks_node_group_arn" {
  value = module.kubernetes.node_group_arn
}

output "eks_cluster_security_group_id" {
  value = module.kubernetes.cluster_security_group_id
}

output "rds_endpoint" {
  value = module.database.database_endpoint
}

output "rds_address" {
  value = module.database.database_address
}

output "rds_port" {
  value = module.database.database_port
}
