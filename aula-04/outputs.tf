# ============================================================
# Outputs da Infraestrutura TechNova
# ============================================================

output "vpc_id" {
  description = "ID da VPC TechNova"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Lista com os IDs das subnets públicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Lista com os IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "api_security_group_id" {
  description = "ID do Security Group da API"
  value       = aws_security_group.api.id
}

output "db_security_group_id" {
  description = "ID do Security Group do banco de dados"
  value       = aws_security_group.db.id
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.api.public_ip
}

output "api_url" {
  description = "URL completa da API TechNova"
  value       = "http://${aws_instance.api.public_ip}:3000"
}

output "ssh_command" {
  description = "Comando SSH para conectar à instância"
  value       = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.api.public_ip}"
}

output "ami_id" {
  description = "ID da AMI Amazon Linux 2023 utilizada"
  value       = data.aws_ami.amazon_linux_2023.id
}

output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.api.id
}
