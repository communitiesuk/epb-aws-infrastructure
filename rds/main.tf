resource "aws_db_instance" "postgres_rds" {
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  db_name                 = replace("${var.prefix}-postgres-db", "-", "")
  vpc_security_group_ids  = var.security_group_ids
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
  allocated_storage       = 5
  storage_type            = "gp2"
  backup_retention_period = 0
  skip_final_snapshot     = true
  username                = "postgres"
  password                = "postgres-password"
  engine_version          = "14.6"
  identifier              = "${var.prefix}-postgres-db"
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "rds_security_group" {
  name   = "${var.prefix}-rds-security-group"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}