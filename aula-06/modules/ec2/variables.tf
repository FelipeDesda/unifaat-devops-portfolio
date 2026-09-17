variable "instance_name" {
  description = "Nome da instância EC2."
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2."
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID da AMI."
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet onde a instância será criada."
  type        = string
}

variable "security_group_ids" {
  description = "IDs dos Security Groups associados."
  type        = list(string)
}

variable "key_name" {
  description = "Nome do key pair da AWS."
  type        = string
}

variable "user_data" {
  description = "Script opcional executado no primeiro boot."
  type        = string
  default     = null
}

variable "environment" {
  description = "Nome do ambiente."
  type        = string
}

variable "project_name" {
  description = "Nome do projeto."
  type        = string
}
