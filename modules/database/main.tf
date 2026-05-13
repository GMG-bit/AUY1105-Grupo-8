# El Subnet Group ahora apunta a las subredes privadas
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name        = "${var.project_name}-db-subnet-group"
  subnet_ids  = var.private_subnet_ids # <--- Usar las subredes privadas
  description = "Grupo de subredes privadas para PostgreSQL"

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier           = "${var.project_name}-postgres"
  engine               = "postgres"
  engine_version       = "16.1"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  
  db_name              = "appdb"
  username             = "dbadmin"
  password             = "PasswordSeguro789!"
  
  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  
  multi_az               = true
  
  # CRUCIAL: Al estar en subredes privadas, debe ser falso.
  # AWS no te permitirá poner 'true' si las subredes no tienen ruta directa a un IGW.
  publicly_accessible    = false 

  skip_final_snapshot    = true
  deletion_protection    = false

  tags = {
    Name = "${var.project_name}-database"
  }
}