# ============================================================
# Outputs — Rede
# ============================================================

output "vpc_id" {
  description = "ID da VPC principal"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID da subnet pública (EC2)"
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas (RDS)"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

# ============================================================
# Outputs — EC2
# ============================================================

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.app_server.public_ip
}

output "ec2_public_dns" {
  description = "DNS público da instância EC2"
  value       = aws_instance.app_server.public_dns
}

output "ec2_ssh_command" {
  description = "Comando SSH para conectar à instância EC2"
  value       = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.app_server.public_ip}"
}

# ============================================================
# Outputs — RDS
# ============================================================

output "rds_endpoint" {
  description = "Endpoint de conexão do RDS PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_port" {
  description = "Porta do RDS PostgreSQL"
  value       = aws_db_instance.postgres.port
}

output "rds_db_name" {
  description = "Nome do banco de dados criado no RDS"
  value       = aws_db_instance.postgres.db_name
}

output "rds_connection_string" {
  description = "String de conexão PostgreSQL (sem senha)"
  value       = "postgresql://${var.db_username}@${aws_db_instance.postgres.endpoint}/${var.db_name}"
  sensitive   = true
}

output "psql_command" {
  description = "Comando psql para conectar ao RDS a partir do EC2"
  value       = "psql -h ${aws_db_instance.postgres.address} -U ${var.db_username} -d ${var.db_name} -W"
  sensitive   = true
}

# ============================================================
# Outputs — Remote State
# ============================================================

output "tfstate_bucket" {
  description = "Nome do bucket S3 que armazena o Terraform state"
  value       = var.tfstate_bucket_name
}
