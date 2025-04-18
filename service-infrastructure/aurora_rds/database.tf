locals {
  cluster_name  = var.name_suffix == null ? "${var.prefix}-aurora-db-cluster" : "${var.prefix}-aurora-db-cluster-${var.name_suffix}"
  instance_name = var.name_suffix == null ? "${var.prefix}-aurora-db" : "${var.prefix}-aurora-db-${var.name_suffix}"
}

resource "aws_rds_cluster" "this" {
  cluster_identifier               = local.cluster_name
  engine                           = "aurora-postgresql"
  engine_version                   = var.postgres_version
  availability_zones               = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  database_name                    = var.db_name
  master_username                  = "postgres"
  master_password                  = random_password.password.result
  backup_retention_period          = var.storage_backup_period
  preferred_backup_window          = "02:00-04:00"
  db_cluster_parameter_group_name  = var.cluster_parameter_group_name
  db_instance_parameter_group_name = var.instance_parameter_group_name

  db_subnet_group_name   = var.subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  storage_encrypted      = true
  skip_final_snapshot    = true
  kms_key_id             = var.kms_key_id
  lifecycle {
    prevent_destroy = true
  }

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.scaling_configuration == null ? [] : [0]
    content {
      max_capacity = var.scaling_configuration.max_capacity
      min_capacity = var.scaling_configuration.min_capacity
    }
  }

}

resource "aws_rds_cluster_instance" "this" {
  count                        = 2
  identifier                   = "${local.instance_name}-${count.index}"
  cluster_identifier           = aws_rds_cluster.this.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.this.engine
  engine_version               = aws_rds_cluster.this.engine_version
  preferred_maintenance_window = count.index == 0 ? "Sun:01:01-Sun:02:01" : "Sun:02:02-Sun:03:02"

  lifecycle {
    prevent_destroy = true
  }
}


