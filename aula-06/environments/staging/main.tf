locals {
  project_name = "technova"
  environment  = "staging"
  vpc_cidr     = "10.1.0.0/16"
}

module "vpc" {
  source       = "../../modules/vpc"
  vpc_cidr     = local.vpc_cidr
  project_name = local.project_name
  environment  = local.environment

  subnets = {
    public-1  = { cidr = "10.1.1.0/24", az = "us-east-1a", type = "public" }
    public-2  = { cidr = "10.1.2.0/24", az = "us-east-1b", type = "public" }
    private-1 = { cidr = "10.1.3.0/24", az = "us-east-1a", type = "private" }
    private-2 = { cidr = "10.1.4.0/24", az = "us-east-1b", type = "private" }
  }
}

module "api_sg" {
  source       = "../../modules/security-group"
  name         = "${local.project_name}-${local.environment}-api-sg"
  vpc_id       = module.vpc.vpc_id
  project_name = local.project_name
  environment  = local.environment

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP publico"
    }
    ,
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH para administracao"
    }
  ]
}

module "rds_sg" {
  source       = "../../modules/security-group"
  name         = "${local.project_name}-${local.environment}-rds-sg"
  vpc_id       = module.vpc.vpc_id
  project_name = local.project_name
  environment  = local.environment

  ingress_rules = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [local.vpc_cidr]
      description = "PostgreSQL interno da VPC"
    }
  ]
}

module "api_server" {
  source             = "../../modules/ec2"
  instance_name      = "${local.project_name}-${local.environment}-api"
  instance_type      = "t2.micro"
  ami_id             = var.ami_id
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.api_sg.sg_id]
  key_name           = var.key_name
  environment        = local.environment
  project_name       = local.project_name

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx || yum install -y nginx
    systemctl enable --now nginx
  EOF
}

module "database" {
  source             = "../../modules/rds"
  db_name            = "technova_staging"
  db_username        = "technova_admin"
  db_password        = var.db_password
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.rds_sg.sg_id]
  instance_class     = "db.t3.micro"
  environment        = local.environment
  project_name       = local.project_name
}
