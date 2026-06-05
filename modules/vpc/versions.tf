# versions.tf - Declara las versiones requeridas de Terraform y de los
# proveedores que utiliza el modulo VPC. Mantener estas restricciones alineadas
# con el repositorio raiz garantiza compatibilidad y builds reproducibles.
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
