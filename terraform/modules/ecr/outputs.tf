output "repository_url" {
  description = "ECR repository URL to use in Jenkinsfile"
  value       = aws_ecr_repository.app.repository_url
}
