# ============================================================
# VPC Principal
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ============================================================
# Subnet Pública (EC2)
# ============================================================

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-${var.availability_zone_1}"
    Tier = "Public"
  }
}

# ============================================================
# Subnets Privadas (RDS — AZs diferentes obrigatórias)
# ============================================================

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name = "${var.project_name}-subnet-private-${var.availability_zone_1}"
    Tier = "Private"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name = "${var.project_name}-subnet-private-${var.availability_zone_2}"
    Tier = "Private"
  }
}

# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ============================================================
# Route Table Pública (com rota para Internet Gateway)
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

# Associação da Route Table pública com a subnet pública
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ============================================================
# Route Table Privada (sem rota para internet — isolamento do RDS)
# ============================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-rt-private"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}
