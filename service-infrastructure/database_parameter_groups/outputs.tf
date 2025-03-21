output "aurora_pg_param_group_name" {
  value = aws_rds_cluster_parameter_group.rds_aurora.name
}

output "rds_pg_param_group_name" {
  value = try(aws_db_parameter_group.rds_db[0].name, "")
}
