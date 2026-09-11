# ============================================================
# Security Group — EC2 (App Server)
# ============================================================

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-sg-ec2"
  description = "Security Group para a instancia EC2 - permite SSH e API"
  vpc_id      = aws_vpc.main.id

  # SSH — acesso administrativo
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API da aplicação
  ingress {
    description = "API porta 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Saída irrestrita (necessária para atualizações e conexão ao RDS)
  egress {
    description = "Todo trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-ec2"
  }
}

# ============================================================
# Security Group — RDS (Banco de Dados)
# ============================================================

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-sg-rds"
  description = "Security Group para o RDS PostgreSQL - permite acesso apenas do EC2"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL — apenas do Security Group do EC2
  ingress {
    description     = "PostgreSQL do EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  # Sem regras de saída explícitas — RDS não precisa iniciar conexões externas
  egress {
    description = "Todo trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-sg-rds"
  }
}
