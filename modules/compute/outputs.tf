output "asg_name" {
  description = "Nombre del Auto Scaling Group creado"
  value       = aws_autoscaling_group.app_asg.name
}

output "launch_template_id" {
  description = "ID de la Launch Template"
  value       = aws_launch_template.app_lt.id
}