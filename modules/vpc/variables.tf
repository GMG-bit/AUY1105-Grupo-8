#archivo variables.tf - Define las variables de entrada para el módulo VPC. Estas variables permiten parametrizar la creación de la VPC, como el nombre del proyecto, el rango de IPs para la VPC y las subredes públicas.
variable "project_name" {
  description = "Nombre del proyecto para etiquetar los recursos"
  type        = string
}

variable "vpc_cidr_block" {
  description = "Rango de IPs para la VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Lista de rangos de IPs para las subredes públicas"
  type        = list(string)
}