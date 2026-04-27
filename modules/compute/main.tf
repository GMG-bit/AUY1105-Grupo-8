variable "project_name" {}
variable "vpc_id" {}
variable "subnet_id" { description = "ID de la subred donde se alojarán" }
variable "security_group_ids" { type = list(string) }

variable "os_type" {
  description = "Sistema Operativo: 'linux' o 'windows'"
  type        = string
}

variable "instance_count" {
  description = "Cantidad de instancias a crear (Requisito: count)"
  type        = number
}

# --- 1. Lógica de Selección de AMI (Imagen) ---

# Buscar AMI de Ubuntu 24.04 LTS (Noble) - REQUISITO 2
data "aws_ami" "ubuntu" {
  count       = var.os_type == "linux" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"] # ID Oficial de Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Buscar AMI de Windows Server 2019
data "aws_ami" "windows" {
  count       = var.os_type == "windows" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

locals {
  ami_id = var.os_type == "linux" ? data.aws_ami.ubuntu[0].id : data.aws_ami.windows[0].id

  user_data_linux = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install apache2 -y
    systemctl start apache2
    systemctl enable apache2
    echo "Hola desde Ubuntu 24.04 (Host: $(hostname))" > /var/www/html/index.html
  EOF

  user_data_windows = <<-EOF
    <powershell>
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    Set-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value "Hola desde Windows App 2"
    </powershell>
  EOF

  user_data = var.os_type == "linux" ? local.user_data_linux : local.user_data_windows
}

# --- 2. Creación de Instancias ---

resource "aws_instance" "server" {
  count = var.instance_count

  ami           = local.ami_id
  instance_type = "t2.micro" # REQUISITO 2
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = var.security_group_ids
  
  user_data = local.user_data

  # Nomenclatura Requerida: <sigla-curso>-<nombre-aplicación>-<tipo-recurso>
  tags = {
    Name        = "AUY1105-${var.project_name}-ec2" # REQUISITO 2
    Environment = "lab"
    OS_Type     = var.os_type
  }
}

output "instance_ips" {
  value = aws_instance.server[*].public_ip
}