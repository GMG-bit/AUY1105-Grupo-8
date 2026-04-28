variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos."
  type        = string
  default     = "us-east-1" # us-east-1 es la estándar en Learner Lab
}

variable "project_name" {
  description = "Nombre del proyecto, usado para etiquetar recursos."
  type        = string
}

variable "vpc_cidr_block" {
  description = "Rango de IPs para la VPC."
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Lista de rangos de IPs para las subredes públicas."
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "instance_count_app1" {
  description = "Cantidad de instancias para la App 1 (Linux)"
  type        = number
  default     = 1
}
