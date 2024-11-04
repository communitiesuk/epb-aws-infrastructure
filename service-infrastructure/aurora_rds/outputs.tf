
output "rds_full_access_policy_arn" {
  value = aws_iam_policy.rds.arn
}

output "rds_cluster_identifier" {
  value = aws_rds_cluster.this.cluster_identifier
}

output "rds_db_password" {
  value = aws_rds_cluster.this.master_password
}

output "rds_db_username" {
  value = aws_rds_cluster.this.master_username
}

locals {
  connection_string        = "postgresql://${aws_rds_cluster.this.master_username == null ? "" : aws_rds_cluster.this.master_username}:${aws_rds_cluster.this.master_password == null ? "" : aws_rds_cluster.this.master_password}@${aws_rds_cluster.this.endpoint == null ? "" : aws_rds_cluster.this.endpoint}/${aws_rds_cluster.this.database_name == null ? "" : aws_rds_cluster.this.database_name}"
  reader_connection_string = replace(local.connection_string, aws_rds_cluster.this.endpoint, aws_rds_cluster.this.reader_endpoint)
}


output "rds_db_connection_string" {
  description = "A libpq (Postgresql) connection string for consuming this database, intended to be set as the environment variable DATABASE_URL"
  value       = local.connection_string
  sensitive   = true
}


output "rds_db_reader_connection_string" {
  description = "A libpq (Postgresql) connection string for consuming this database, intended to be set as the environment variable DATABASE_URL"
  value       = local.reader_connection_string
  sensitive   = true
}
