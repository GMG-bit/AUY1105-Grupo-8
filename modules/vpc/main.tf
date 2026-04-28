# Obtenemos la lista de Zonas de Disponibilidad (AZ) en la región actual
# Esto nos permite crear subredes en diferentes AZs (buena práctica)
data "aws_availability_zones" "available" {
  state = "available"
}

# 1. Crear la VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "AUY1105-${var.project_name}-vpc"
  }
}

# Bloquea todo el tráfico en el Security Group default de la VPC
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "AUY1105-${var.project_name}-default-sg"
  }
}

# 2. Crear el Internet Gateway (para darle salida a Internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "AUY1105-${var.project_name}-igw"
  }
}

# 3. Crear una Tabla de Rutas (para definir cómo sale el tráfico)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Esta ruta envía todo el tráfico desconocido (0.0.0.0/0) al Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "AUY1105-${var.project_name}-public-rt"
  }
}

# 4. Crear las Subredes Públicas (usamos count para crear varias)
resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130:Arquitectura del curso requiere instancias en subnet publica con IP publica
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  # Asigna el CIDR correspondiente a cada subred según su índice
  cidr_block        = var.public_subnet_cidrs[count.index]
  # Asigna una AZ distinta a cada subred
  availability_zone = data.aws_availability_zones.available.names[count.index]
  # Hace que las instancias en esta subred obtengan IP pública automáticamente
  map_public_ip_on_launch = true

  tags = {
    Name = "AUY1105-${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# 5. VPC Flow Logs (auditoría de tráfico de red)
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_kms_key" "vpc_flow_logs" {
  description             = "KMS key para encriptar VPC Flow Logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.id}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.vpc_flow_logs.arn
}

resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = data.aws_iam_role.lab_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
}

# 6. Asociar la Tabla de Rutas con las Subredes
# Esto "activa" la ruta a internet para nuestras subredes
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
