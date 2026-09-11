# ============================================================
# Bootstrap — Provider e configuração Terraform
# Responsável por criar o backend remoto (S3 + DynamoDB)
# antes de qualquer outra infra ser provisionada.
#
# ATENÇÃO: Este módulo NÃO usa backend remoto — o state fica
# local (terraform.tfstate) pois é ele quem cria o bucket.
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Sem backend remoto aqui: o state deste módulo é local
  # e deve ser versionado (ou guardado com segurança manualmente).
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Module    = "bootstrap"
      ManagedBy = "Terraform"
    }
  }
}
