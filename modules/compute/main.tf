# Launch Template: Define cómo serán las instancias del ASG
resource "aws_launch_template" "app_lt" {
  #checkov:skip=CKV_AWS_341:Se asume que la AMI base es segura
  #checkov:skip=CKV_AWS_88:Las instancias requieren IP publica debido a restricciones de arquitectura académica
  name_prefix   = "${var.project_name}-template-"
  image_id      = "ami-0e2c8caa4b6378d8c" # Ubuntu 24.04 LTS en us-east-1
  instance_type = "t3.small"
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = var.security_group_ids
  }

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

  # USER DATA: Instalación automatizada de Docker, AWS CLI, Sincronización S3, Metadatos IMDSv2, Banner y CloudWatch Agent
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Actualizar paquetes
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common wget gnupg2 unzip

              # --- CONFIGURACION DE MEMORIA SWAP (1 GB) ---
              # 1. Crear un archivo vacio de 1GB asignando espacio del SSD
              fallocate -l 1G /swapfile
              # 2. Restringir permisos de lectura y escritura exclusivamente a root por seguridad
              chmod 600 /swapfile
              # 3. Formatear el archivo como sistema de archivos de intercambio
              mkswap /swapfile
              # 4. Activar el espacio swap inmediatamente en el kernel
              swapon /swapfile
              # 5. Agregar el registro de montaje al fstab para mantenerlo persistente tras reinicios
              echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

              # 1. Instalar Docker (Usar docker.io para evitar problemas de repositorios externos en Ubuntu 24.04)
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              
              # 2. Instalar AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # 3. Descargar el Sitio Generico desde S3 de forma dinamica y ligera
              mkdir -p /var/www/html
              aws s3 sync s3://${var.assets_bucket_id}/html /var/www/html --region ${var.aws_region}

              # 4. Obtener metadatos de la instancia mediante IMDSv2
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
              PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
              AZ=$(curl -s -H "X-aws-ec2-metadata-token: \$TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

              # 5. Diseñar e inyectar el Banner Flotante Premium para demostrar el Balanceo de Carga
              BANNER_HTML="<div style='background:linear-gradient(135deg, #623CE4 0%, #4A2CB3 100%);color:#ffffff;text-align:center;padding:12px;font-size:15px;font-family:sans-serif;position:sticky;top:0;left:0;width:100%;z-index:99999;box-shadow:0 4px 15px rgba(0,0,0,0.2);display:flex;justify-content:center;align-items:center;gap:20px;'><span>⚡ <strong>TechNova Server</strong></span><span>🆔 ID Instancia: <code style='background:rgba(255,255,255,0.25);padding:2px 6px;border-radius:4px;'>\$INSTANCE_ID</code></span><span>🔌 IP Privada: <code style='background:rgba(255,255,255,0.25);padding:2px 6px;border-radius:4px;'>\$PRIVATE_IP</code></span><span>📍 Zona: <code style='background:rgba(255,255,255,0.25);padding:2px 6px;border-radius:4px;'>\$AZ</code></span></div>"
              
              # Reemplazar la etiqueta body inicial para agregar el banner al principio de todos los archivos HTML
              sed -i 's|<body class="main-layout">|<body class="main-layout">'"\$BANNER_HTML"'|g' /var/www/html/*.html

              # Reemplazar el placeholder de texto simple en la página de inicio
              sed -i 's#<!-- BANNER_PLACEHOLDER -->#Servidor: '"\$INSTANCE_ID"'  |  IP Privada: '"\$PRIVATE_IP"'  |  Zona: '"\$AZ"'#g' /var/www/html/index.html

              # 6. Levantar Nginx Dockerizado montando el directorio estatico modificado
              docker run -d -p 80:80 --name web_server -v /var/www/html:/usr/share/nginx/html nginx

              # 7. Instalar el AWS CloudWatch Agent
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