# archivo outputs.tf - Define las salidas del módulo Compute. Estas salidas permiten que otros módulos o el módulo raíz puedan acceder a los recursos creados en este módulo, como los IDs de las instancias y sus IPs públicas.
output "instance_ids" {
  description = "IDs de las instancias creadas"
  value       = aws_instance.server[*].id
}
output "instance_ips" {
  description = "IPs públicas de las instancias creadas"
  # Usamos el splat operator [*] porque podrías tener más de una instancia
  value = aws_instance.server[*].public_ip
}