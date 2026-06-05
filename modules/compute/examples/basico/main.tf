# Ejemplo funcional de uso del modulo de Computo.
# Crea la red base (VPC) y un Security Group minimo, y luego despliega el
# Auto Scaling Group + Launch Template del modulo de computo sobre esa red.

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "Region de AWS donde se despliegan los recursos"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Nombre del par de claves EC2 existente para acceso SSH"
  type        = string
}

variable "target_group_arn" {
  description = "ARN del Target Group del balanceador al que se asocia el ASG"
  type        = string
}

variable "assets_bucket_id" {
  description = "ID del bucket S3 con los archivos estaticos del sitio"
  type        = string
}

# Red base para el ejemplo (reutiliza el modulo VPC del repositorio)
module "vpc" {
  source = "../../../vpc"

  project_name         = "ejemplo-computo"
  vpc_cidr_block       = "10.20.0.0/16"
  public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.101.0/24", "10.20.102.0/24"]
}

# Security Group minimo para las instancias del ejemplo
resource "aws_security_group" "ejemplo_sg" {
  name        = "ejemplo-computo-sg"
  description = "SG de ejemplo para las instancias del ASG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Invocacion del modulo de Computo
module "compute" {
  source = "../../" # Apunta a la raiz del modulo de computo

  project_name       = "ejemplo-computo"
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.ejemplo_sg.id]
  key_name           = var.key_name
  target_group_arn   = var.target_group_arn
  assets_bucket_id   = var.assets_bucket_id
  aws_region         = var.aws_region

  desired_capacity = 2
  min_size         = 2
  max_size         = 3
}

output "asg_name" {
  description = "Nombre del Auto Scaling Group creado"
  value       = module.compute.asg_name
}

output "launch_template_id" {
  description = "ID de la Launch Template"
  value       = module.compute.launch_template_id
}
