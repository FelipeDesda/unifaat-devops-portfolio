# ============================================================
# EC2 — App Server (subnet pública)
# ============================================================

resource "aws_instance" "app_server" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_pair_name

  # User data: instala o cliente PostgreSQL para testar conexão com o RDS
  # Os valores do RDS são injetados pelo Terraform no momento do apply
  user_data = <<-EOF
    #!/bin/bash
    set -ex

    # Atualiza pacotes
    dnf update -y

    # Instala o cliente PostgreSQL 15
    dnf install -y postgresql15

    # Instala ferramentas úteis de diagnóstico
    dnf install -y telnet nc

    # Registra conclusão no log
    echo "Configuracao concluida em $(date)" >> /var/log/userdata.log
    echo "PostgreSQL client versao: $(psql --version)" >> /var/log/userdata.log

    # Cria script auxiliar de conexão ao RDS com valores injetados pelo Terraform
    cat > /home/ec2-user/connect-rds.sh << 'SCRIPT'
#!/bin/bash
# Script para conectar ao RDS PostgreSQL
# Valores injetados pelo Terraform no momento do provisionamento
RDS_ENDPOINT="${aws_db_instance.postgres.address}"
DB_NAME="${var.db_name}"
DB_USER="${var.db_username}"

echo "Conectando ao RDS: $RDS_ENDPOINT"
psql -h "$RDS_ENDPOINT" -U "$DB_USER" -d "$DB_NAME" -W
SCRIPT

    chmod +x /home/ec2-user/connect-rds.sh
    chown ec2-user:ec2-user /home/ec2-user/connect-rds.sh
  EOF

  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-app-server"
  }
}
