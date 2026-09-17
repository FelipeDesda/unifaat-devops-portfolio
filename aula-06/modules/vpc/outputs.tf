output "vpc_id" {
  description = "ID da VPC criada."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas, ordenados pelo nome."
  value       = [for name in sort(keys(var.subnets)) : aws_subnet.this[name].id if var.subnets[name].type == "public"]
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas, ordenados pelo nome."
  value       = [for name in sort(keys(var.subnets)) : aws_subnet.this[name].id if var.subnets[name].type == "private"]
}
