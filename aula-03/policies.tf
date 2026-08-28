# =============================================================================
# POLICY 1 — S3 Read-Only para o grupo developers
# Permite leitura em qualquer bucket com prefixo "technova-"
# =============================================================================

resource "aws_iam_policy" "s3_read" {
  name        = "SEURA-technova-s3-read"
  path        = "/technova/"
  description = "Permite s3:GetObject e s3:ListBucket em buckets technova-* (menor privilégio)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListTechnovaBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = "arn:aws:s3:::technova-*"
      },
      {
        Sid    = "ReadTechnovaObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectTagging",
        ]
        Resource = "arn:aws:s3:::technova-*/*"
      }
    ]
  })

  tags = {
    Purpose = "S3 read-only access for developers"
  }
}

# Anexa s3-read ao grupo developers
resource "aws_iam_group_policy_attachment" "developers_s3_read" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_read.arn
}

# =============================================================================
# POLICY 2 — EC2 + S3 Full para o grupo platform-eng
# EC2: Describe + Start/Stop (somente instâncias com tag Project=TechNova)
# S3 : Leitura e escrita em buckets technova-*
# =============================================================================

resource "aws_iam_policy" "ec2_s3_full" {
  name        = "SEURA-technova-ec2-s3-full"
  path        = "/technova/"
  description = "EC2 Describe/Start/Stop (tag condition) + S3 read/write em technova-*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EC2 — Describe sem condição (somente leitura de metadados)
      {
        Sid    = "EC2DescribeAll"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups",
        ]
        Resource = "*"
      },
      # EC2 — Start/Stop restrito a instâncias com tag Project=TechNova
      {
        Sid    = "EC2StartStopTagged"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances",
        ]
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Project" = "TechNova"
          }
        }
      },
      # S3 — Listagem de buckets technova-*
      {
        Sid    = "S3ListTechnovaBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:ListBucketMultipartUploads",
        ]
        Resource = "arn:aws:s3:::technova-*"
      },
      # S3 — Leitura e escrita de objetos em technova-*
      {
        Sid    = "S3ReadWriteTechnovaObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectTagging",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts",
        ]
        Resource = "arn:aws:s3:::technova-*/*"
      }
    ]
  })

  tags = {
    Purpose = "EC2 and S3 full access for platform engineers"
  }
}

# Anexa ec2-s3-full ao grupo platform-eng
resource "aws_iam_group_policy_attachment" "platform_eng_ec2_s3_full" {
  group      = aws_iam_group.platform_eng.name
  policy_arn = aws_iam_policy.ec2_s3_full.arn
}

# =============================================================================
# POLICY 3 — Deny Destructive para o grupo developers
# Impede que qualquer usuário do grupo execute ações Delete* ou Terminate*
# =============================================================================

resource "aws_iam_policy" "deny_destructive" {
  name        = "SEURA-technova-deny-destructive"
  path        = "/technova/"
  description = "Deny explícito para Delete* e Terminate* — proteção extra sobre o grupo developers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDestructiveS3"
        Effect = "Deny"
        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy",
          "s3:DeleteBucketWebsite",
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDestructiveEC2"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "ec2:DeleteVolume",
          "ec2:DeleteSnapshot",
          "ec2:DeleteSecurityGroup",
          "ec2:DeleteKeyPair",
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyDestructiveIAM"
        Effect = "Deny"
        Action = [
          "iam:DeleteUser",
          "iam:DeleteGroup",
          "iam:DeleteRole",
          "iam:DeletePolicy",
          "iam:DeleteAccessKey",
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Purpose = "Guardrail: prevent destructive actions by developers"
  }
}

# Anexa deny-destructive ao grupo developers (proteção extra)
resource "aws_iam_group_policy_attachment" "developers_deny_destructive" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.deny_destructive.arn
}

# =============================================================================
# POLICY 4 — Política restritiva para lucas-intern (inline no user)
# Restringe ainda mais o escopo: somente ListBucket e GetObject,
# sem acesso a GetObjectVersion ou ações de metadata extra
# =============================================================================

resource "aws_iam_user_policy" "lucas_intern_restricted" {
  name = "SEURA-technova-lucas-intern-restricted"
  user = aws_iam_user.lucas_intern.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InternS3ReadOnlyRestricted"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
        ]
        Resource = [
          "arn:aws:s3:::technova-*",
          "arn:aws:s3:::technova-*/*",
        ]
      },
      # Bloqueia explicitamente qualquer ação de escrita que possa vir de herança futura
      {
        Sid    = "InternDenyWrite"
        Effect = "Deny"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutBucketPolicy",
          "ec2:*",
          "iam:*",
        ]
        Resource = "*"
      }
    ]
  })
}
