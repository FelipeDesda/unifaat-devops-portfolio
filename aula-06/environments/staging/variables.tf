variable "aws_region" {
  description = "Região AWS do ambiente."
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI Linux compatível com a região escolhida."
  type        = string
}

variable "key_name" {
  description = "Key pair existente na AWS."
  type        = string
}

variable "db_password" {
  description = "Senha do usuário master do RDS."
  type        = string
  sensitive   = true
}
