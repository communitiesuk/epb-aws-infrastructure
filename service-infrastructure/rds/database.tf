resource "aws_db_instance" "postgres_rds" {
  identifier              = "${var.prefix}-${var.engine}-db"
  db_name                 = var.db_name
  engine                  = var.engine
  instance_class          = var.instance_class
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  db_subnet_group_name    = var.subnet_group_name
  allocated_storage       = var.storage_size
  storage_type            = var.engine == "aurora-postgresql" ? "io1" : "gp2"
  backup_retention_period = var.storage_backup_period
  skip_final_snapshot     = true
  username                = "postgres"
  password                = random_password.password.result
  engine_version          = local.engine_version
  iops = var.engine == "aurora-postgresql" ? 1000 : null
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
