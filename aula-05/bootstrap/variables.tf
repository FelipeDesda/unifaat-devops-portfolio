# ============================================================
# Variáveis — Bootstrap
# ============================================================

variable "aws_region" {
  description = "Região AWS onde os recursos de bootstrap serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto — usado em tags e no nome da tabela DynamoDB"
  type        = string
  default     = "technova"
}

variable "tfstate_bucket_name" {
  description = "Nome globalmente único do bucket S3 para o Terraform state"
  type        = string
  default     = "technova-tfstate-unifaat"
}
