# versions.tf - Declara las versiones requeridas de Terraform y de los
# proveedores empleados en el repositorio raiz que orquesta los modulos.
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Ultima version mayor del proveedor
    }
  }
}
