# =============================================================================
# TRUST POLICY — permite que o serviço EC2 assuma esta role
# =============================================================================

data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# =============================================================================
# PERMISSIONS POLICY — Read/Write em buckets technova-app-data-*
# =============================================================================

resource "aws_iam_policy" "ec2_role_s3_app_data" {
  name        = "SEURA-technova-ec2-role-s3-app-data"
  path        = "/technova/"
  description = "Permite que instâncias EC2 façam read/write em buckets technova-app-data-*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListAppDataBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = "arn:aws:s3:::technova-app-data-*"
      },
      {
        Sid    = "ReadWriteAppDataObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
        ]
        Resource = "arn:aws:s3:::technova-app-data-*/*"
      }
    ]
  })

  tags = {
    Purpose = "S3 read/write for EC2 instances (app data buckets)"
  }
}

# =============================================================================
# IAM ROLE — SEURA-technova-ec2-role
# =============================================================================

resource "aws_iam_role" "ec2_role" {
  name               = "SEURA-technova-ec2-role"
  path               = "/technova/"
  description        = "Role assumida por instâncias EC2 para acesso ao S3 de dados da aplicação"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust_policy.json

  # Garante que o Terraform não remova outras políticas anexadas manualmente
  managed_policy_arns = []

  tags = {
    Purpose = "EC2 service role for S3 app data access"
  }
}

# Anexa a permissions policy à role
resource "aws_iam_role_policy_attachment" "ec2_role_s3_app_data" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_role_s3_app_data.arn
}

# =============================================================================
# INSTANCE PROFILE — SEURA-technova-ec2-profile
# Necessário para associar a role a instâncias EC2
# =============================================================================

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "SEURA-technova-ec2-profile"
  path = "/technova/"
  role = aws_iam_role.ec2_role.name

  tags = {
    Purpose = "Instance profile for EC2 S3 app data role"
  }
}
