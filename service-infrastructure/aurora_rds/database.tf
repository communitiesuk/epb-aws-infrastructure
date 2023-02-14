resource "aws_rds_cluster" "this" {
  cluster_identifier      = "${var.prefix}-aurora-db-cluster"
  engine                  = "aurora-postgresql"
  engine_version          = "14.5"
  availability_zones      = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  database_name           = var.db_name
  master_username         = "postgres"
  master_password         = random_password.password.result
  backup_retention_period = var.storage_backup_period
  preferred_backup_window = "02:00-04:00"

  db_subnet_group_name   = var.subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]

  storage_encrypted   = true
  skip_final_snapshot = true
}

resource "aws_rds_cluster_instance" "this" {
  count              = 2
  identifier         = "${var.prefix}-aurora-db-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
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
