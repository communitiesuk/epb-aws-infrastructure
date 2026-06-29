module "display_refresh_orchestration" {
  source = "./step_functions"
  prefix = "${var.prefix}-display"
  region = var.region

  ecs_cluster_arn             = var.ecs_cluster_arn
  ecs_task_definition_arn     = var.ecs_task_exec_arn
  ecs_container_name          = var.ecs_migration_container_name
  ecs_subnet_ids              = var.ecs_subnet_ids
  ecs_security_group_id       = var.ecs_security_group_id
  ecs_task_role_arn           = var.ecs_task_role_arn
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  ecs_rake_command            = ["bundle", "exec", "rake", "refresh_materialized_view"]
  ecs_materialized_view_name  = "mvw_dec_search"
  glue_populate_job_name      = module.populate_dec_etl.etl_job_name
  glue_delete_job_name        = module.delete_iceberg_data.etl_job_name
  glue_zip_export_job_name    = module.export_dec_data_by_year.etl_job_name
}

module "non_domestic_refresh_orchestration" {
  source = "./step_functions"
  prefix = "${var.prefix}-non_domestic"
  region = var.region

  ecs_cluster_arn             = var.ecs_cluster_arn
  ecs_task_definition_arn     = var.ecs_task_exec_arn
  ecs_container_name          = var.ecs_migration_container_name
  ecs_subnet_ids              = var.ecs_subnet_ids
  ecs_security_group_id       = var.ecs_security_group_id
  ecs_task_role_arn           = var.ecs_task_role_arn
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  ecs_rake_command            = ["bundle", "exec", "rake", "refresh_materialized_view"]
  ecs_materialized_view_name  = "mvw_commercial_search"
  glue_populate_job_name      = module.populate_non_domestic_etl.etl_job_name
  glue_delete_job_name        = module.delete_iceberg_data.etl_job_name
  glue_zip_export_job_name    = module.export_non_domestic_data_by_year.etl_job_name
}

module "domestic_refresh_orchestration" {
  source = "./step_functions"
  prefix = "${var.prefix}-domestic"
  region = var.region

  ecs_cluster_arn             = var.ecs_cluster_arn
  ecs_task_definition_arn     = var.ecs_task_exec_arn
  ecs_container_name          = var.ecs_migration_container_name
  ecs_subnet_ids              = var.ecs_subnet_ids
  ecs_security_group_id       = var.ecs_security_group_id
  ecs_task_role_arn           = var.ecs_task_role_arn
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  ecs_rake_command            = ["bundle", "exec", "rake", "refresh_materialized_view"]
  ecs_materialized_view_name  = "mvw_domestic_search"
  glue_populate_job_name      = module.populate_domestic_etl.etl_job_name
  glue_delete_job_name        = module.delete_iceberg_data.etl_job_name
  glue_zip_export_job_name    = module.export_domestic_data_by_year.etl_job_name
}
