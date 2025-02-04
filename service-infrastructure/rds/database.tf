resource "aws_db_instance" "postgres_rds" {
  identifier              = "${var.prefix}-postgres-db"
  db_name                 = var.db_name
  engine                  = "postgres"
  multi_az                = var.multi_az
  engine_version          = var.postgres_version
  instance_class          = var.instance_class
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  db_subnet_group_name    = var.subnet_group_name
  allocated_storage       = var.storage_size
  storage_type            = "gp2"
  storage_encrypted       = true
  backup_retention_period = var.storage_backup_period
  skip_final_snapshot     = true
  username                = "postgres"
  password                = random_password.password.result
  parameter_group_name    = var.parameter_group_name

  lifecycle {
    prevent_destroy = true
  }
}
