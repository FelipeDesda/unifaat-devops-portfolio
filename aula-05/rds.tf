# ============================================================
# DB Subnet Group — agrupa as 2 subnets privadas em AZs distintas
# ============================================================

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group"
  description = "Subnet group para o RDS PostgreSQL da TechNova"
  subnet_ids  = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ============================================================
# RDS — PostgreSQL 15 (Free Tier / Lab)
# ============================================================

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres"

  # Engine
  engine         = "postgres"
  engine_version = var.db_engine_version

  # Instância e Storage
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"
  storage_encrypted = true

  # Banco de dados inicial
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Rede e segurança
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Alta Disponibilidade (desativado para lab/free tier)
  multi_az = false

  # Backups e manutenção
  backup_retention_period = 0
  skip_final_snapshot     = true # Apenas para ambiente de lab

  # Parâmetros de atualização
  auto_minor_version_upgrade = true
  deletion_protection        = false

  tags = {
    Name = "${var.project_name}-postgres"
  }
}
