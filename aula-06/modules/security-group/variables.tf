variable "name" {
  description = "Nome do Security Group."
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o Security Group será criado."
  type        = string
}

variable "ingress_rules" {
  description = "Regras de entrada do Security Group."
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "environment" {
  description = "Nome do ambiente."
  type        = string
}

variable "project_name" {
  description = "Nome do projeto usado nas tags."
  type        = string
}
