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

variable "private_subnet_cidrs" {
  description = "CIDRs para subredes privadas"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"] # Ajustado para alinearse con la VPC (dentro del rango 10.1.0.0/16)
}

variable "instance_count_app1" {
  description = "Cantidad de instancias para la App 1 (Linux)"
  type        = number
  default     = 2
}

variable "key_name" {
  description = "Nombre del Key Pair de AWS para acceso SSH a las instancias"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR permitido para acceso SSH."
  type        = string
  default     = "0.0.0.0/0"
}

variable "subscription_email" {
  description = "Correo electronico para recibir alertas de CloudWatch a traves de SNS"
  type        = string
  default     = "gas.mardones@duocuc.cl"
}

variable "cpu_alert_threshold" {
  description = "Umbral porcentual de uso de CPU para activar alertas"
  type        = number
  default     = 70
}

variable "memory_alert_threshold" {
  description = "Umbral porcentual de uso de Memoria para activar alertas"
  type        = number
  default     = 70
}
