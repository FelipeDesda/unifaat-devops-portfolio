variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto — usado em tags e prefixos de recursos"
  type        = string
  default     = "TechNova"
}

variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser 'dev', 'staging' ou 'prod'."
  }
}

variable "aluno" {
  description = "Nome do aluno responsável pelo recurso"
  type        = string
  default     = "Felipe Damasceno"
}

variable "ra" {
  description = "Registro Acadêmico do aluno"
  type        = string
  default     = "6325128"
}

variable "s3_bucket_prefix" {
  description = "Prefixo dos buckets S3 gerenciados pela TechNova"
  type        = string
  default     = "technova-*"
}

variable "s3_app_data_prefix" {
  description = "Prefixo dos buckets S3 de dados da aplicação (usados pela EC2 role)"
  type        = string
  default     = "technova-app-data-*"
}
