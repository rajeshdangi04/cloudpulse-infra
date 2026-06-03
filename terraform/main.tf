provider "aws" {
  region = var.region
}

module "vpc" {
  source               = "./modules/vpc"
  region               = var.region
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "eks" {
  source             = "./modules/eks"
  subnet_ids         = module.vpc.subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  cluster_name       = var.cluster_name
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  project_name       = var.project_name
}

module "ecr" {
  source        = "./modules/ecr"
  ecr_repo_name = var.ecr_repo_name
}
