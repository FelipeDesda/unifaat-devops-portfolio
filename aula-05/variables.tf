# ============================================================
# Variáveis Gerais
# ============================================================

variable "aws_region" {
  description = "Região AWS onde os recursos serão provisionados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto usado em tags e identificadores"
  type        = string
  default     = "technova"
}

# ============================================================
# Variáveis de Rede (VPC)
# ============================================================

variable "vpc_cidr" {
  description = "CIDR block da VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block da subnet pública (EC2)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block da 1ª subnet privada (RDS)"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block da 2ª subnet privada (RDS - AZ diferente)"
  type        = string
  default     = "10.0.11.0/24"
}

variable "availability_zone_1" {
  description = "Primeira Availability Zone"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Segunda Availability Zone (deve ser diferente da primeira)"
  type        = string
  default     = "us-east-1b"
}

# ============================================================
# Variáveis do EC2
# ============================================================

variable "ec2_instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "ec2_ami" {
  description = "AMI ID para a instância EC2 (Amazon Linux 2023 us-east-1)"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "key_pair_name" {
  description = "Nome do Key Pair AWS para acesso SSH à instância EC2"
  type        = string
}

# ============================================================
# Variáveis do RDS
# ============================================================

variable "db_instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Tamanho do storage em GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Versão do PostgreSQL"
  type        = string
  default     = "15"
}

variable "db_name" {
  description = "Nome do banco de dados inicial"
  type        = string
  default     = "technova_db"
}

variable "db_username" {
  description = "Usuário administrador do banco de dados"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha do usuário administrador do banco de dados"
  type        = string
  sensitive   = true
}

# ============================================================
# Variáveis do Remote State (Bootstrap)
# ============================================================

variable "tfstate_bucket_name" {
  description = "Nome do bucket S3 para armazenar o Terraform state"
  type        = string
  default     = "technova-tfstate-unifaat"
}
