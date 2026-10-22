# TechNova Aula 10 - Terraform Variables
# Substitua os valores conforme seu ambiente

aws_region      = "us-east-1"
environment     = "production"
project_name    = "technova-aula10"
ec2_key_name    = "vockey" # Trocar pelo nome da sua key pair no Lab

# Networking
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# EC2
ec2_instance_type = "t2.micro"
allowed_ssh_cidr  = "0.0.0.0/0" # Restringir ao seu IP em produção

# ECR
ecr_repository_name = "technova-api"
