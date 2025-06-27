output "rds_full_access_policy_arn" {
  value = aws_iam_policy.rds.arn
}

output "rds_instance_identifier" {
  value = aws_db_instance.postgres_rds.identifier
}

output "rds_db_password" {
  value = aws_db_instance.postgres_rds.password
}

output "rds_db_username" {
  value = aws_db_instance.postgres_rds.username
}

locals {
  connection_string = "postgresql://${aws_db_instance.postgres_rds.username == null ? "" : aws_db_instance.postgres_rds.username}:${aws_db_instance.postgres_rds.password == null ? "" : aws_db_instance.postgres_rds.password}@${aws_db_instance.postgres_rds.endpoint == null ? "" : aws_db_instance.postgres_rds.endpoint}/${aws_db_instance.postgres_rds.db_name == null ? "" : aws_db_instance.postgres_rds.db_name}"
}

output "rds_db_connection_string" {
  description = "A libpq (Postgresql) connection string for consuming this database, intended to be set as the environment variable DATABASE_URL"
  value       = local.connection_string
  sensitive   = true
}
