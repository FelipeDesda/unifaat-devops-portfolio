# ============================================================
# Tabela DynamoDB — Locking do Terraform State
#
# Evita que dois `terraform apply` rodem ao mesmo tempo e
# corrompam o state. O Terraform exige a chave "LockID" (string).
# ============================================================

resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "${var.project_name}-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST" # sem capacidade provisionada — custo zero em idle
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Proteção contra deleção acidental da tabela de lock
  lifecycle {
    prevent_destroy = true
  }
}
