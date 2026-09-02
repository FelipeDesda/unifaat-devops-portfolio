# ============================================================
# IAM Role para EC2
# ============================================================

resource "aws_iam_role" "ec2_role" {
  name        = "technova-ec2-role"
  description = "IAM Role que permite à instância EC2 acessar recursos AWS"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "technova-ec2-role"
  }
}

# ============================================================
# Attach Policy — AmazonS3ReadOnlyAccess
# ============================================================

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# ============================================================
# Instance Profile
# ============================================================

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "technova-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "technova-ec2-instance-profile"
  }
}
