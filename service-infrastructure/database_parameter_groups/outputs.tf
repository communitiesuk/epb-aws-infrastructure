output "aurora_pglogical_target_pg_name" {
  value = resource.aws_rds_cluster_parameter_group.target.name
}

output "rds_pglogical_target_pg_name" {
  value = resource.aws_db_parameter_group.target.name
}

output "aurora_pglogical_source_pg_name" {
  value = resource.aws_rds_cluster_parameter_group.source.name
}

output "rds_pglogical_source_pg_name" {
  value = resource.aws_db_parameter_group.source.name
}
