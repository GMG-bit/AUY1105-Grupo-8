output "db_endpoint" {
  description = "El endpoint de conexion a la base de datos MySQL"
  value       = aws_db_instance.mysql.endpoint
}
