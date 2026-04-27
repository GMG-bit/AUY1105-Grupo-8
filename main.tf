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
  #checkov:skip=CKV_AWS_24:SSH desde 0.0.0.0/0 requerido para acceso al lab
  #checkov:skip=CKV_AWS_382:Egress irrestricto requerido para conectividad del lab
  name        = "${var.project_name}-servers-sg"
  description = "Permite trafico SSH"
  vpc_id      = module.vpc.vpc_id

  # SSH para Linux
  ingress {
    description = "Permite trafico SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite toda la salida
  egress {
    description = "Permite todo el trafico saliente"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
}
