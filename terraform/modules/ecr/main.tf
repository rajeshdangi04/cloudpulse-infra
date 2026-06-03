variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "cloudpulse-app"
}

resource "aws_ecr_repository" "app" {
  name         = var.ecr_repo_name
  force_delete = true
}

