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
