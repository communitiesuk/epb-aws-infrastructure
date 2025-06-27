locals {
  instance_name = var.name_suffix == null ? "${var.prefix}-postgres-db" : "${var.prefix}-postgres-db-${var.name_suffix}"
}

resource "aws_db_instance" "postgres_rds" {
  identifier              = local.instance_name
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
  kms_key_id              = var.kms_key_id

  lifecycle {
    prevent_destroy = true
  }
}
