terraform {
  backend "s3" {
    bucket = "cloudpulse-terraform-state"
    key    = "infra/terraform.tfstate"
    region = "ap-south-1"
  }
}
