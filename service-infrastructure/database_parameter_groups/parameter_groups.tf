resource "aws_db_parameter_group" "rds_db" {
  name   = "rds-pg"
  family = "postgres14"
}

resource "aws_rds_cluster_parameter_group" "rds_aurora" {
  name   = "aurora-pg"
  family = "aurora-postgresql14"
}
