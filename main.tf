# Archivo principal de Terraform. Aquí se definen los recursos principales
# y se llaman a los módulos para crear la infraestructura completa.
# 1. Red base
module "vpc" {
  source              = "./modules/vpc"
  project_name        = var.project_name
  vpc_cidr_block      = var.vpc_cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
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
    security_groups = [module.LoadBalancer.alb_sg_id] 
  }

  ingress {
    description = "SSH publico - requerido en Learner Lab"
    from_port   = 22
    to_port     = 22
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

  desired_capacity   = 1
  min_size           = 1
  max_size           = 2 # Ajustado para no saturar los límites de tu Learner Lab
}