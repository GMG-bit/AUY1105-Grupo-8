output "vpc_id" {
  description = "ID de la VPC principal"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs de las subredes publicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas"
  value       = module.vpc.private_subnet_ids
}

output "alb_dns_name" {
  description = "El nombre de dominio DNS publico del balanceador de carga"
  value       = module.balanceador.alb_dns_name
}

output "url_sitio_web" {
  description = "URL principal para acceder al sitio de e-commerce de TechNova a traves del ALB"
  value       = "http://${module.balanceador.alb_dns_name}"
}

output "database_endpoint" {
  description = "Endpoint de conexion para la base de datos MySQL Multi-AZ"
  value       = module.database.db_endpoint
}