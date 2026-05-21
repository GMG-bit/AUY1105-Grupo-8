# El Subnet Group ahora apunta a las subredes privadas
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name        = "${var.project_name}-db-subnet-group"
  subnet_ids  = var.private_subnet_ids
  description = "Grupo de subredes privadas para MySQL"

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  #checkov:skip=CKV_AWS_118:Evaluacion requiere password en codigo por simplicidad académica
  #checkov:skip=CKV_AWS_133:Respaldos manejados de forma centralizada
  #checkov:skip=CKV_AWS_354:Performance Insights no requerido por el alcance
  #checkov:skip=CKV_AWS_16:Se deshabilita snapshot final para evitar costos en laboratorios temporales
  identifier            = "${var.project_name}-mysql"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t4g.small"
  allocated_storage     = 50
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "appdb"
  username = "dbadmin"
  password = "Duoc.1234" # En producción, usar un método seguro para manejar credenciales (ej: Secrets Manager)

  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  multi_az = true

  # CRUCIAL: Al estar en subredes privadas, debe ser falso.
  publicly_accessible = false

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name = "${var.project_name}-database"
  }
}

resource "aws_security_group" "db_sg" {
  name   = "${var.project_name}-db-sg"
  vpc_id = var.vpc_id # Usamos la variable en lugar de la referencia directa

  # Permitir tráfico MySQL (puerto 3306) desde el Security Group de los servidores (ASG)
  ingress {
    description     = "Acceso MySQL desde los servidores"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id] # Usamos la variable ec2_security_group_id
  }

  egress {
    description = "Salida de base de datos a cualquier destino"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}
