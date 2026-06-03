output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs — for Load Balancer"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs — for EKS nodes"
  value       = aws_subnet.private[*].id
}

# Keep subnet_ids as alias for backward compatibility
output "subnet_ids" {
  description = "All subnet IDs (public + private)"
  value       = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
}
