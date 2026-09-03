# ============================================================
# Data Source — AMI Amazon Linux 2023 (mais recente)
# ============================================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================
# Key Pair — gerado via Terraform (TLS provider)
# ============================================================

resource "tls_private_key" "technova" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "technova" {
  key_name   = var.key_name
  public_key = tls_private_key.technova.public_key_openssh

  tags = {
    Name = "technova-key-pair"
  }
}

# Salva a chave privada localmente para uso no SSH
resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.technova.private_key_pem
  filename        = pathexpand(var.private_key_path)
  file_permission = "0600"
}

# ============================================================
# User Data — instala Node.js 18, Git e inicia a API
# ============================================================

locals {
  user_data = <<-EOF
#!/bin/bash
set -xe
exec > /var/log/user-data.log 2>&1

# Atualiza pacotes
dnf update -y

# Instala Git e Node.js 18
dnf install -y git
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs

# Cria diretório da aplicação
mkdir -p /opt/technova
cd /opt/technova

# Tenta clonar o repositório; se falhar, cria API de exemplo
if ! git clone https://github.com/KauanIzidoro/technova-api.git . 2>/dev/null; then
  echo "AVISO: clone falhou — criando API de exemplo"
  cat > /opt/technova/index.js <<'JSEOF'
const http = require('http');
const PORT = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ status: 'ok', app: 'technova-api', message: 'API no ar!' }));
});
server.listen(PORT, () => console.log('Servidor na porta ' + PORT));
JSEOF
  echo '{"name":"technova-api","version":"1.0.0","main":"index.js"}' > /opt/technova/package.json
else
  npm install
fi

# Detecta entrypoint real
ENTRYPOINT="index.js"
if [ -f package.json ]; then
  MAIN=$(node -e "try{console.log(require('./package.json').main||'')}catch(e){}" 2>/dev/null)
  [ -n "$MAIN" ] && [ -f "$MAIN" ] && ENTRYPOINT="$MAIN"
fi

# Cria serviço systemd
cat > /etc/systemd/system/technova-api.service <<UNIT
[Unit]
Description=TechNova API
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/technova
ExecStart=/usr/bin/node /opt/technova/$${ENTRYPOINT}
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment=PORT=3000
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
UNIT

# Ajusta permissoes e inicia o servico
chown -R ec2-user:ec2-user /opt/technova
systemctl daemon-reload
systemctl enable technova-api
systemctl start technova-api
EOF
}

# ============================================================
# EC2 Instance
# ============================================================

resource "aws_instance" "api" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.api.id]
  key_name               = aws_key_pair.technova.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.lab.name

  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true

    tags = {
      Name = "technova-ec2-root-volume"
    }
  }

  tags = {
    Name = "technova-ec2-api"
  }
}
