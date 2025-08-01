output "aurora_pg_param_group_name" {
  value = aws_rds_cluster_parameter_group.rds_aurora.name
}

output "aurora_pg_17_serverless_param_group_name" {
  value = aws_rds_cluster_parameter_group.rds_aurora_serverless_17.name
}

output "rds_pg_param_group_name" {
  value = try(aws_db_parameter_group.rds_db[0].name, "")
}
