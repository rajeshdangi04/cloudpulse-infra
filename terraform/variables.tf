variable "region" {
  description = "AWS region where to deploy our resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name — used for tagging and naming all resources"
  type        = string
  default     = "cloudpulse"
}

variable "environment" {
  description = "Environment name (production, staging, dev)"
  type        = string
  default     = "production"
}

# -------------------------------------------------------
# VPC Variables
# -------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for main VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (LoadBalancer yahan)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (EKS nodes yahan)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

# -------------------------------------------------------
# EKS Variables
# -------------------------------------------------------

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "cloudpulse-cluster"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 3
}

# -------------------------------------------------------
# ECR Variables
# -------------------------------------------------------

variable "ecr_repo_name" {
  description = "ECR repository name for Docker images"
  type        = string
  default     = "cloudpulse-app"
}

