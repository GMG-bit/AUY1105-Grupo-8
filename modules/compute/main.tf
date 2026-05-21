# Launch Template: Define cómo serán las instancias del ASG
resource "aws_launch_template" "app_lt" {
  #checkov:skip=CKV_AWS_341:Se asume que la AMI base es segura
  #checkov:skip=CKV_AWS_88:Las instancias requieren IP publica debido a restricciones de arquitectura académica
  name_prefix   = "${var.project_name}-template-"
  image_id      = "ami-0e2c8caa4b6378d8c" # Ubuntu 24.04 LTS en us-east-1
  instance_type = "t3.small"
  key_name      = var.key_name

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    name = "LabInstanceProfile" # Perfil de instancia IAM pre-creado en AWS Academy Learner Lab
  }

  block_device_mappings {
    device_name = "/dev/sda1" # Volumen de arranque para Ubuntu
    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Fuerza IMDSv2 para alta seguridad
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true # Habilita monitoreo detallado de 1 minuto en CloudWatch
  }

  # USER DATA: Instalación automatizada de Docker, Nginx de prueba y CloudWatch Agent
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Actualizar paquetes
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common wget gnupg2 unzip

              # 1. Instalar Docker
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io
              systemctl start docker
              systemctl enable docker
              
              # Test temporal para que el ALB pase el Health Check (Nginx en Docker)
              docker run -d -p 80:80 nginx

              # 2. Instalar el AWS CloudWatch Agent
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
              dpkg -i -E ./amazon-cloudwatch-agent.deb

              # 3. Crear el archivo de configuracion del CloudWatch Agent
              # Captura métricas detalladas de CPU, Memoria, Disco y Red
              cat <<'JSON' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              {
                "agent": {
                  "metrics_collection_interval": 60,
                  "run_as_user": "root"
                },
                "metrics": {
                  "append_dimensions": {
                    "InstanceId": "$${aws:InstanceId}",
                    "InstanceType": "$${aws:InstanceType}"
                  },
                  "metrics_collected": {
                    "cpu": {
                      "measurement": [
                        "cpu_usage_active"
                      ],
                      "metrics_collection_interval": 60,
                      "totalcpu": true
                    },
                    "disk": {
                      "measurement": [
                        "used_percent"
                      ],
                      "metrics_collection_interval": 60,
                      "resources": [
                        "/"
                      ]
                    },
                    "mem": {
                      "measurement": [
                        "used_percent"
                      ],
                      "metrics_collection_interval": 60
                    },
                    "net": {
                      "measurement": [
                        "bytes_sent",
                        "bytes_recv"
                      ],
                      "metrics_collection_interval": 60,
                      "resources": [
                        "*"
                      ]
                    }
                  }
                }
              }
              JSON

              # 4. Iniciar el CloudWatch Agent con la configuracion cargada
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-asg-node"
      Project     = var.project_name
      BackupClass = "DailyBackup" # Etiqueta clave para la seleccion de AWS Backup
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name_prefix         = "${var.project_name}-asg-"
  vpc_zone_identifier = var.subnet_ids         # Subnets públicas de la VPC (us-east-1a, us-east-1b)
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

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}