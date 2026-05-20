# Archivo principal de Terraform. Aquí se definen los recursos principales
# y se llaman a los módulos para crear la infraestructura completa.
# 1. Red base
module "vpc" {
  source              = "./modules/vpc"
  project_name        = var.project_name
  vpc_cidr_block      = var.vpc_cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs # Agregado para permitir la creación de subredes privadas
}

# 2. Grupo de Seguridad para los servidores
resource "aws_security_group" "servers_sg" {
  name        = "${var.project_name}-servers-sg"
  vpc_id      = module.vpc.vpc_id

  # Permitir HTTP solo desde el Security Group del ALB (Buenas prácticas de seguridad)
  ingress {
    description     = "Acceso HTTP desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.balanceador.alb_sg_id] # Referencia dinámica al SG del ALB
  }

  ingress {
    description = "SSH publico - gestionado por variable"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Balanceador de carga público (requiere las subnets de la VPC)
module "balanceador" {
  source            = "./modules/balanceador"
  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

# 4. Cómputo Elástico (ASG) - Consume el Target Group del Balanceador
module "app1_linux_compute" {
  source             = "./modules/compute"
  project_name       = var.project_name
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.servers_sg.id]
  key_name           = var.key_name
  target_group_arn   = module.balanceador.target_group_arn # Conexión dinámica ASG -> ALB

  desired_capacity   = 2
  min_size           = 2
  max_size           = 4 # Ajustado según requerimiento de escalabilidad
}
# ---------------------------------------------------------
# DATABASE (PostgreSQL Multi-AZ)
# ---------------------------------------------------------
module "database" {
  source                = "./modules/database"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids # Usamos las subnets privadas para la base de datos
  ec2_security_group_id = aws_security_group.servers_sg.id # Crucial para permitir el tráfico EC2 -> DB
}