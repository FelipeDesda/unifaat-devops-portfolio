# ============================================================
# Bucket S3 — Armazenamento do Terraform State
#
# NOTA: O ambiente AWS Academy bloqueia s3:GetBucketObjectLockConfiguration
# via SCP, o que impede o import do recurso aws_s3_bucket.
# Solução: referenciar o bucket existente via data source e
# gerenciar apenas as configurações complementares como recursos.
# ============================================================

data "aws_s3_bucket" "tfstate" {
  bucket = var.tfstate_bucket_name
}

# ============================================================
# Versionamento — permite recuperar versões anteriores do state
# ============================================================

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = data.aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ============================================================
# Encriptação — SSE-S3 (AES-256) aplicada em todos os objetos
# ============================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = data.aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ============================================================
# Block Public Access — garante que o state nunca fique público
# ============================================================

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = data.aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================
# Bucket Policy — força encriptação e HTTPS em todas as chamadas
# ============================================================

resource "aws_s3_bucket_policy" "tfstate" {
  bucket = data.aws_s3_bucket.tfstate.id

  depends_on = [aws_s3_bucket_public_access_block.tfstate]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          data.aws_s3_bucket.tfstate.arn,
          "${data.aws_s3_bucket.tfstate.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "DenyUnencryptedUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${data.aws_s3_bucket.tfstate.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}
