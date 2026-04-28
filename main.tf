# Archivo principal de Terraform. Aquí se definen los recursos principales
# y se llaman a los módulos para crear la infraestructura completa.

# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------
# Llama a nuestro módulo local que está en la carpeta modules/vpc
module "vpc" {
  source = "./modules/vpc"

  # Aquí le pasamos las variables que el módulo necesita
  project_name        = var.project_name
  vpc_cidr_block      = var.vpc_cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
}

# ---------------------------------------------------------
# SECURITY GROUP
# ---------------------------------------------------------
# Security Group compartido para los servidores
resource "aws_security_group" "servers_sg" {
  #checkov:skip=CKV_AWS_24:Puerto 22 habilitado para acceso SSH directo - SSM no disponible en AWS Learner Lab
  name        = "${var.project_name}-servers-sg"
  description = "Security Group para servidores con acceso SSH y egreso web"
  vpc_id      = module.vpc.vpc_id
# Regla para permitir tráfico web (Nginx)
  ingress {
    #checkov:skip=CKV_AWS_260:Puerto 80 habilitado para todo el publico, para verificar pagina web
    description = "Acceso HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitido para tráfico web
  }
  # HTTPS - SSM Session Manager + repositorios seguros

  ingress {
    description = "SSH publico - requerido en Learner Lab (SSM no disponible)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS - repositorios seguros
  egress {
    description = "Permite trafico HTTPS saliente"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP - repositorios de paquetes
  egress {
    description = "Permite trafico HTTP saliente"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AUY1105-${var.project_name}-servers-sg"
  }
}

# ---------------------------------------------------------
# APP 1: LINUX (1 Instancia)
# ---------------------------------------------------------
module "app1_linux_compute" {
  source = "./modules/compute"
  project_name = var.project_name
  # Ponemos la instancia en la primera subred pública
  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [aws_security_group.servers_sg.id]
  os_type            = "linux"
  instance_count     = var.instance_count_app1
  key_name           = var.key_name
}
