terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project    = var.project_name
      ManagedBy  = "Terraform"
      Aluno      = var.aluno
      RA         = var.ra
      Disciplina = "DevOps - UniFAAT 2026-2"
      Aula       = "03"
    }
  }
}
