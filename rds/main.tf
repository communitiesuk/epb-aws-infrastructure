resource "random_password" "password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "postgres_rds" {
  identifier              = "${var.prefix}-postgres-db"
  db_name                 = var.db_name
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  allocated_storage       = 5
  storage_type            = "gp2"
  backup_retention_period = 0
  skip_final_snapshot     = true
  username                = "postgres"
  password                = random_password.password.result
  engine_version          = "14.6"
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "rds_security_group" {
  name   = "${var.prefix}-rds-security-group"
  vpc_id = var.vpc_id

  ingress {
    security_groups = var.security_group_ids
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
  }
}