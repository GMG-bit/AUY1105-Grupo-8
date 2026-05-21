variable "project_name" {
  description = "Nombre del proyecto para etiquetar los recursos"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC principal"
  type        = string
}

variable "public_subnet_ids" {
  description = "Lista de IDs de las subredes publicas para el ALB"
  type        = list(string)
}
