output "vpc_id" {
  description = "ID de la VPC principal"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subredes públicas"
  value       = module.vpc.public_subnet_ids
}

output "app1_linux_ips" {
  description = "IPs públicas de los servidores Linux"
  value       = module.app1_linux_compute.instance_ips
}

output "url_sitio_web" {
  description = "URL para acceder al servidor Nginx"
  # Construye la URL usando las IPs que vienen del módulo de cómputo
  value = [for ip in module.app1_linux_compute.instance_ips : "http://${ip}"]
}
output "database_endpoint" {
  description = "Endpoint de conexion para la base de datos PostgreSQL"
  value       = module.database.db_endpoint
}