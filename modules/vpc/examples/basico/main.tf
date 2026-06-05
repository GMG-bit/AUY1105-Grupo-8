# Ejemplo funcional de uso del modulo VPC.
# Despliega una VPC con subredes publicas y privadas en dos zonas de
# disponibilidad, lista para alojar capas de computo y datos.

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
  region = "us-east-1"
}

module "vpc" {
  source = "../../" # Apunta a la raiz del modulo VPC

  project_name         = "ejemplo-technova"
  vpc_cidr_block       = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs = ["10.1.101.0/24", "10.1.102.0/24"]
}

# Salidas del ejemplo para verificar el despliegue
output "vpc_id" {
  description = "ID de la VPC creada por el modulo"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subredes publicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = module.vpc.private_subnet_ids
}
