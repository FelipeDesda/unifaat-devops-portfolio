# ============================================================
# Variáveis Globais
# ============================================================

variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Ambiente de implantação"
  type        = string
  default     = "development"
}

variable "owner_ra" {
  description = "RA do aluno responsável pelos recursos"
  type        = string
}

# ============================================================
# Variáveis de Rede
# ============================================================

variable "vpc_cidr" {
  description = "Bloco CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Blocos CIDR das subnets públicas (uma por AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Blocos CIDR das subnets privadas (uma por AZ)"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Lista de Availability Zones a utilizar"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ============================================================
# Variáveis de EC2
# ============================================================

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nome do Key Pair que será criado no AWS"
  type        = string
  default     = "technova-key"
}

variable "private_key_path" {
  description = "Caminho local onde a chave privada SSH será salva"
  type        = string
  default     = "~/.ssh/technova-key.pem"
}
