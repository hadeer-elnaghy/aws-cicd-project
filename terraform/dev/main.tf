
module "network" {
  source = "../modules/vpc"

  vpc_name             = var.network_name
  vpc_cidr             = var.network_cidr
  public_subnet_cidrs  = var.public_network_ranges
  private_subnet_cidrs = var.private_network_ranges
  availability_zones   = var.zone_names
  cluster_name         = var.cluster_name
}

module "iam" {
  source = "../modules/iam"

  project_name = var.project_name
}

module "container_registry" {
  source = "../modules/ecr"

  repository_name = var.repository_name
}

module "kubernetes" {
  source = "../modules/eks"

  cluster_name     = var.cluster_name
  cluster_version  = var.cluster_version
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  private_subnet_ids = module.network.private_subnet_ids

  node_instance_types = var.node_machine_types

  desired_size = var.node_desired_count
  min_size     = var.node_min_count
  max_size     = var.node_max_count

  eks_user_arn = var.eks_user_arn

  depends_on = [module.iam]
}

module "database" {
  source = "../modules/rds"

  database_name         = var.database_name
  initial_database_name = var.initial_database_name
  database_username     = var.database_username
  database_password     = var.database_password

  private_subnet_ids = module.network.private_subnet_ids
  vpc_id             = module.network.vpc_id

  eks_cluster_security_group_id = module.kubernetes.cluster_security_group_id

  depends_on = [module.kubernetes]
}
