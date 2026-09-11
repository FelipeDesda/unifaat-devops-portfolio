# ============================================================
# Outputs — Bootstrap (S3 + DynamoDB)
# Use estes valores para configurar o backend nos demais módulos
# ============================================================

output "tfstate_bucket_name" {
  description = "Nome do bucket S3 que armazena o Terraform state"
  value       = data.aws_s3_bucket.tfstate.id
}

output "tfstate_bucket_arn" {
  description = "ARN do bucket S3 do Terraform state"
  value       = data.aws_s3_bucket.tfstate.arn
}

output "tfstate_lock_table_name" {
  description = "Nome da tabela DynamoDB usada para locking do state"
  value       = aws_dynamodb_table.tfstate_lock.name
}
