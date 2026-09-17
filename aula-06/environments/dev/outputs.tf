output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID da VPC de desenvolvimento."
}

output "api_instance_id" {
  value       = module.api_server.instance_id
  description = "ID da API em desenvolvimento."
}

output "api_public_ip" {
  value       = module.api_server.public_ip
  description = "IP público da API em desenvolvimento."
}

output "database_endpoint" {
  value       = module.database.db_endpoint
  description = "Endpoint do banco de desenvolvimento."
}
