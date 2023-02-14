output "rds_db_arn" {
  value = aws_rds_cluster.this.arn
}

output "rds_db_password" {
  value = aws_rds_cluster.this.master_password
}

output "rds_db_username" {
  value = aws_rds_cluster.this.master_username
}

output "rds_db_connection_string" {
  description = "A libpq (Postgresql) connection string for consuming this database, intended to be set as the environment variable DATABASE_URL"
  value       = "postgresql://${aws_rds_cluster.this.master_username}@${aws_rds_cluster.this.endpoint}/${aws_rds_cluster.this.database_name}?password=${aws_rds_cluster.this.master_password}"
  sensitive   = true
}
