output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "ecr_url" {
  description = "ECR repository URL — paste this in Jenkinsfile ECR_REPO"
  value       = module.ecr.repository_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs — Load Balancer runs here"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs — EKS nodes run here"
  value       = module.vpc.private_subnet_ids
}
