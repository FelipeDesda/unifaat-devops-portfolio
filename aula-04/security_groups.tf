# ============================================================
# Security Group — API Node.js
# ============================================================

resource "aws_security_group" "api" {
  name        = "technova-sg-api"
  description = "Security Group para a API TechNova (portas 22 e 3000)"
  vpc_id      = aws_vpc.main.id

  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API Node.js
  ingress {
    description = "API Node.js"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Todo tráfego de saída permitido
  egress {
    description = "Egress all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "technova-sg-api"
  }
}

# ============================================================
# Security Group — Banco de Dados (uso futuro)
# ============================================================

resource "aws_security_group" "db" {
  name        = "technova-sg-db"
  description = "Security Group para o banco de dados PostgreSQL (acesso interno a VPC)"
  vpc_id      = aws_vpc.main.id

  # PostgreSQL — apenas de dentro da VPC
  ingress {
    description = "PostgreSQL interno"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Todo tráfego de saída permitido
  egress {
    description = "Egress all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "technova-sg-db"
  }
}
