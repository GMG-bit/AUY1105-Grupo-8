# providers.tf - Configuracion del proveedor AWS para el repositorio raiz.
# Las restricciones de version de Terraform y proveedores se declaran en versions.tf.
provider "aws" {
  region = var.aws_region
}
