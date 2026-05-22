# ==============================================================================
# Archivo Principal de Terraform - TechNova Solutions
# Arquitectura de Alta Disponibilidad, Monitoreo y Recuperación ante Desastres (DR)
# ==============================================================================

# Origen de datos para capturar dinámicamente el Account ID de AWS
data "aws_caller_identity" "current" {}

locals {
  # Sanitize the project name: trim leading/trailing spaces and replace internal spaces with hyphens
  project_name_clean = replace(trimspace(var.project_name), " ", "-")
}

# 1. Red Base (VPC, Subredes Públicas/Privadas, NAT Gateway y Flow Logs)
module "vpc" {
  source               = "./modules/vpc"
  project_name         = local.project_name_clean
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# 2. Grupo de Seguridad para los Servidores (Capa de Cómputo EC2)
resource "aws_security_group" "servers_sg" {
  #checkov:skip=CKV_AWS_24:Se permite SSH de forma abierta por defecto para el entorno de aprendizaje académico, restringible por variable
  name        = "${local.project_name_clean}-servers-sg"
  description = "Security Group para las instancias EC2 en el ASG"
  vpc_id      = module.vpc.vpc_id

  # Permitir HTTP únicamente desde el Security Group del ALB (Buenas prácticas de seguridad)
  ingress {
    description     = "Acceso HTTP exclusivo desde el ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.balanceador.alb_sg_id]
  }

  # Permitir SSH según CIDR configurado por variable
  ingress {
    description = "Acceso SSH de gestion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    description = "Permitir todo el trafico de salida hacia el NAT Gateway o Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name_clean}-servers-sg"
  }
}

# 2.5 Capa de Almacenamiento Estático para Assets (Amazon S3)
locals {
  mime_types = {
    "html"  = "text/html"
    "css"   = "text/css"
    "js"    = "application/javascript"
    "png"   = "image/png"
    "jpg"   = "image/jpeg"
    "jpeg"  = "image/jpeg"
    "gif"   = "image/gif"
    "svg"   = "image/svg+xml"
    "woff"  = "font/woff"
    "woff2" = "font/woff2"
    "ttf"   = "font/sfnt"
    "ico"   = "image/x-icon"
  }
}

resource "aws_s3_bucket" "assets" {
  #checkov:skip=CKV_AWS_18:Access logging no es critico para este entorno de laboratorio academico
  #checkov:skip=CKV_AWS_144:Cross-region replication no es necesario para el alcance del laboratorio
  bucket        = "${lower(local.project_name_clean)}-assets-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets_encryption" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "assets_block" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "assets_versioning" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "html_files" {
  for_each = fileset("${path.module}/Sitio Generico/html", "**/*")

  bucket       = aws_s3_bucket.assets.id
  key          = "html/${each.value}"
  source       = "${path.module}/Sitio Generico/html/${each.value}"
  etag         = filemd5("${path.module}/Sitio Generico/html/${each.value}")
  content_type = lookup(local.mime_types, element(split(".", each.value), length(split(".", each.value)) - 1), "application/octet-stream")
}

# 3. Capa de Balanceo de Carga (Application Load Balancer)
module "balanceador" {
  source            = "./modules/balanceador"
  project_name      = local.project_name_clean
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

# 4. Capa de Cómputo Horizontal (Auto Scaling Group + Launch Template)
module "app1_linux_compute" {
  source             = "./modules/compute"
  project_name       = local.project_name_clean
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.servers_sg.id]
  key_name           = var.key_name
  target_group_arn   = module.balanceador.target_group_arn
  assets_bucket_id   = aws_s3_bucket.assets.id
  aws_region         = var.aws_region

  desired_capacity = 2
  min_size         = 2
  max_size         = 3 # Ajustado al requerimiento exacto: mín:2, deseado:2, máx:3
}


# 5. Capa de Datos Cifrada (RDS MySQL Multi-AZ)
module "database" {
  source                = "./modules/database"
  project_name          = local.project_name_clean
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  ec2_security_group_id = aws_security_group.servers_sg.id
}

# ------------------------------------------------------------------------------
# MÓDULO DE MONITOREO Y ALERTAS (Amazon CloudWatch & SNS)
# ------------------------------------------------------------------------------

# 6. Tema de Notificaciones SNS para Alertas
resource "aws_sns_topic" "alerts" {
  #checkov:skip=CKV_AWS_26:Cifrado KMS para el tema SNS no es critico para el alcance de este laboratorio academico
  name              = "${local.project_name_clean}-alerts-topic"
  kms_master_key_id = "alias/aws/sns" # Cifrado por defecto de SNS para mayor seguridad
}

# Suscripción de Correo al Tema SNS
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = trimspace(var.subscription_email)
}

# Alarma de CloudWatch: Alta Utilización de CPU en el Auto Scaling Group (>70%)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.project_name_clean}-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_alert_threshold
  alarm_description   = "Se activa si la utilizacion de CPU supera el ${var.cpu_alert_threshold}% en el ASG por mas de 2 minutos"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = module.app1_linux_compute.asg_name
  }
}

# Alarma de CloudWatch: Alta Utilización de Memoria (Reportada por el CloudWatch Agent, >70%)
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${local.project_name_clean}-high-memory-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = var.memory_alert_threshold
  alarm_description   = "Se activa si el uso de Memoria RAM supera el ${var.memory_alert_threshold}% por mas de 2 minutos"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceType = "t3.small"
  }
}

# Dashboard Ejecutivo y Técnico de CloudWatch
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.project_name_clean}-monitoring-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.app1_linux_compute.asg_name]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Uso Promedio de CPU del Auto Scaling Group (%)"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["CWAgent", "used_percent", "InstanceType", "t3.small"]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Uso Promedio de Memoria RAM (CloudWatch Agent) (%)"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.balanceador.alb_arn_suffix]
          ]
          period = 60
          stat   = "Sum"
          region = var.aws_region
          title  = "Total de Peticiones Procesadas por el ALB"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${local.project_name_clean}-mysql"]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "Uso de CPU de Base de Datos RDS MySQL Multi-AZ (%)"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# PLAN DE RESPALDOS Y DR (AWS Backup)
# ------------------------------------------------------------------------------

# Bóveda de Respaldo Centralizada
resource "aws_backup_vault" "vault" {
  #checkov:skip=CKV_AWS_166:KMS de la boveda no requiere configuracion avanzada para el alcance academico, usa KMS por defecto
  name = "${local.project_name_clean}-backup-vault"
}

# Plan de Respaldo Diario con Retención de 7 días
resource "aws_backup_plan" "backup_plan" {
  name = "${local.project_name_clean}-backup-plan"

  rule {
    rule_name         = "daily-backup-rule"
    target_vault_name = aws_backup_vault.vault.name
    schedule          = "cron(0 5 * * ? *)" # Ejecucion diaria a las 05:00 AM UTC (fuera de horas pico)

    lifecycle {
      delete_after = 7 # Retencion automatica por 7 dias
    }
  }
}

# Selección de Recursos (EC2 por Tag, y base de datos RDS MySQL por ARN)
resource "aws_backup_selection" "backup_selection" {
  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole" # Utiliza LabRole preexistente de AWS Academy
  name         = "${local.project_name_clean}-backup-resources"
  plan_id      = aws_backup_plan.backup_plan.id

  # Selecciona instancias EC2 con la etiqueta BackupClass = DailyBackup
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupClass"
    value = "DailyBackup"
  }

  # Selecciona explícitamente el recurso de Base de Datos RDS MySQL
  resources = [
    "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:${local.project_name_clean}-mysql"
  ]
}