output "instance_ips" {
  description = "IPs públicas de las instancias creadas"
  value       = aws_instance.server[*].public_ip
}

output "instance_ids" {
  description = "IDs de las instancias creadas"
  value       = aws_instance.server[*].id
}
