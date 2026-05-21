# Security Group para el ALB
resource "aws_security_group" "alb_sg" {
  #checkov:skip=CKV_AWS_119:ALB publico requiere acceso HTTP/HTTPS desde cualquier origen
  #checkov:skip=CKV_AWS_260:ALB requiere ingress HTTP y HTTPS publico
  name        = "${var.project_name}-alb-sg"
  vpc_id      = var.vpc_id
  description = "Security Group para el Application Load Balancer de TechNova"

  ingress {
    description = "Permitir HTTP de forma publica"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Permitir HTTPS de forma publica"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Permitir todo el trafico de salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# El Balanceador de Aplicaciones (ALB)
resource "aws_lb" "main" {
  #checkov:skip=CKV_AWS_91:Se asume que Flow Logs de la VPC capturan trafico del ALB y no es critico habilitar access logs en laboratorios temporales
  #checkov:skip=CKV_AWS_150:Evaluacion no requiere deletion protection para permitir destruccion de laboratorios
  #checkov:skip=CKV_AWS_152:WAF no requerido para el alcance de esta evaluacion academica
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# Listener HTTP (Puerto 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}