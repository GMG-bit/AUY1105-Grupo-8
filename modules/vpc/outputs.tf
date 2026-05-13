#archivo outputs.tf - Define las salidas del módulo VPC. Estas salidas permiten que otros módulos o el módulo raíz puedan acceder a los recursos creados en este módulo, como el ID de la VPC y los IDs de las subredes públicas.
output "vpc_id" {
  description = "El ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Lista de IDs de las subredes públicas creadas"
  # Esto genera una lista con los IDs de todas las subredes creadas por el "count"
  value = aws_subnet.public[*].id
}