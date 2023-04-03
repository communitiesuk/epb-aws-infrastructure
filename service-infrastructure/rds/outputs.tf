output "rds_full_access_policy_arn" {
  value = aws_iam_policy.rds.arn
}

output "rds_db_password" {
  value = aws_db_instance.postgres_rds.password
}

output "rds_db_username" {
  value = aws_db_instance.postgres_rds.username
}

output "rds_db_connection_string" {
  description = "A libpq (Postgresql) connection string for consuming this database, intended to be set as the environment variable DATABASE_URL"
  value       = "postgresql://${aws_db_instance.postgres_rds.username}:${aws_db_instance.postgres_rds.password}@${aws_db_instance.postgres_rds.endpoint}/${aws_db_instance.postgres_rds.db_name}"
  sensitive   = true
}
