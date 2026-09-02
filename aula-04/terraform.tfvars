# ============================================================
# Valores das variáveis — ajuste conforme necessário
# ============================================================

# Região AWS (AWS Academy usa us-east-1 por padrão)
aws_region = "us-east-1"

# Ambiente
environment = "development"

# RA do aluno — ALTERE para o seu RA
owner_ra = "SEU-RA-AQUI"

# Rede
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# EC2
instance_type    = "t2.micro"
key_name         = "technova-key"
private_key_path = "~/.ssh/technova-key.pem"
