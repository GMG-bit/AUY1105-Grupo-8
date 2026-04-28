variable "project_name" {}
variable "subnet_id" { description = "ID de la subred donde se alojará la instancia" }
variable "security_group_ids" { type = list(string) }

variable "os_type" {
  description = "Sistema Operativo: 'linux'"
  type        = string
}

variable "instance_count" {
  description = "Cantidad de instancias a crear"
  type        = number
}

variable "key_name" {
  description = "Nombre del Key Pair de AWS para acceso SSH"
  type        = string
}

# --- 1. Selección de AMI ---

# Buscar la última AMI de Ubuntu 24.04 LTS (Noble)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID oficial de Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# --- 2. Creación de Instancias ---

resource "aws_instance" "server" {
  #checkov:skip=CKV_AWS_135:La politica OPA del proyecto exige t2.micro, el cual no soporta EBS optimization
  count = var.instance_count

  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t2.micro"
  subnet_id            = var.subnet_id
  key_name             = var.key_name
  monitoring           = true
  iam_instance_profile = "LabInstanceProfile"
  vpc_security_group_ids = var.security_group_ids
  user_data = local.user_data_linux
  # Fuerza IMDSv2 (deshabilita IMDSv1)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Disco raíz cifrado
  root_block_device {
    encrypted = true
  }
  tags = {
    Name        = "AUY1105-${var.project_name}-ec2"
    Environment = "lab"
    OS_Type     = var.os_type
  }
}
locals {
  user_data_linux = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx git
    systemctl start nginx
    systemctl enable nginx
    git clone --depth 1 https://github.com/GMG-bit/AUY1105-Grupo-8.git /tmp/repo
    cp -r "/tmp/repo/Sitio Generico/html/." /var/www/html/
    rm -rf /tmp/repo
  EOF
}