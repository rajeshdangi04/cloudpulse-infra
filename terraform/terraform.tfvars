# Copy this file to terraform.tfvars and fill in your values
# Usage: cp terraform.tfvars.example terraform.tfvars

region       = "ap-south-1"
project_name = "cloudpulse"
environment  = "production"

# -------------------------------------------------------
# VPC Variables
# -------------------------------------------------------

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# -------------------------------------------------------
# EKS Variables
# -------------------------------------------------------

cluster_name       = "cloudpulse-cluster"
node_instance_type = "t3.small"
node_desired_size  = 2
node_min_size      = 1
node_max_size      = 3

# -------------------------------------------------------
# ECR Variables
# -------------------------------------------------------

ecr_repo_name = "cloudpulse-app"
