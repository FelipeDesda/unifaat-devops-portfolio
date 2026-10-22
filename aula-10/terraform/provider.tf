terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 para state remoto
  # Descomente após criar o bucket
  # backend "s3" {
  #   bucket         = "technova-terraform-state"
  #   key            = "aula-10/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "technova-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "TechNova-Aula10"
      Environment = var.environment
      ManagedBy   = "Terraform"
      GitOps      = "true"
    }
  }
}
