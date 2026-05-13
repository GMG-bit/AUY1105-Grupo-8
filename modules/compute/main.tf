# Launch Template: Define cómo serán las instancias del ASG
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-template-"
  image_id      = "ami-0e2c8caa4b6378d8c" # Tu AMI de Ubuntu 24.04
  instance_type = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids

  # USER DATA: Instalación automatizada de Docker para el futuro
  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
              add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              apt-get update -y
              apt-get install -y docker-ce
              systemctl start docker
              systemctl enable docker
              
              # Test temporal para que el ALB pase el Health Check (Nginx en Docker)
              docker run -d -p 80:80 nginx
              EOF
  )
  lifecycle {
    create_before_destroy = true
  }
}
# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.subnet_ids # Subnets públicas de la VPC
  target_group_arns   = [var.target_group_arn] # Vinculación automática al ALB

  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_type         = "ELB" # El ASG confía en los health checks del ALB
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-worker"
    propagate_at_launch = true
  }
}