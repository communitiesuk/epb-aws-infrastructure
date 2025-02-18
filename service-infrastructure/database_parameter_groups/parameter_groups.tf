resource "aws_db_parameter_group" "rds_db" {
  count  = var.has_rds == true ? 1 : 0
  name   = "rds-pg"
  family = "postgres14"
}



resource "aws_rds_cluster_parameter_group" "rds_aurora" {
  name   = var.aurora_name
  family = "aurora-postgresql14"

  dynamic "parameter" {
    for_each = var.has_md_5_password == true ? [0] : []
    content {
      name  = "password_encryption"
      value = "MD5"
    }
  }

}

