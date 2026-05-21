output "target_group_arn" {
  description = "El ARN del Target Group del ALB"
  value       = aws_lb_target_group.app_tg.arn
}

output "alb_sg_id" {
  description = "El ID del Security Group del ALB"
  value       = aws_security_group.alb_sg.id
}

output "alb_dns_name" {
  description = "El DNS publico del Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  description = "El sufijo ARN del ALB para su uso en metricas de CloudWatch"
  value       = aws_lb.main.arn_suffix
}