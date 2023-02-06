output "rds_db_arn" {
  value = aws_db_instance.postgres_rds.arn
}

output "rds_db_password" {
  value = aws_db_instance.postgres_rds.password
}

output "rds_db_username" {
  value = aws_db_instance.postgres_rds.username
}

output "rds_db_hostname" {
  value = aws_db_instance.postgres_rds.endpoint
}

output "rds_db_port" {
  value = aws_db_instance.postgres_rds.port
}

output "rds_db_name" {
  value = aws_db_instance.postgres_rds.db_name
}

output "rds_db_endpoint" {
  value = aws_db_instance.postgres_rds.endpoint
}