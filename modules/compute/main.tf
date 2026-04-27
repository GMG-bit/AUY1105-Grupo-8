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
  count = var.instance_count

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id     = var.subnet_id

  vpc_security_group_ids = var.security_group_ids

  tags = {
    Name        = "AUY1105-${var.project_name}-ec2"
    Environment = "lab"
    OS_Type     = var.os_type
  }
}
