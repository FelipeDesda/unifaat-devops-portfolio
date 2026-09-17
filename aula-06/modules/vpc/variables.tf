variable "vpc_cidr" {
  description = "CIDR block da VPC."
  type        = string
}

variable "project_name" {
  description = "Nome do projeto usado nas tags."
  type        = string
}

variable "environment" {
  description = "Nome do ambiente."
  type        = string
}

variable "subnets" {
  description = "Mapa de subnets a criar, com CIDR, AZ e tipo public ou private."
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))

  validation {
    condition     = alltrue([for subnet in values(var.subnets) : contains(["public", "private"], subnet.type)])
    error_message = "Cada subnet deve ter type public ou private."
  }
}
