locals {
  group_name         = aws_scheduler_schedule_group.start-pipeline.name
  scheduler_role_arn = aws_iam_role.scheduler.arn
}

module "addressing_pipeline" {
  source              = "./schedule"
  name                = "addressing-pipeline"
  group_name          = local.group_name
  schedule_expression = "cron(33 13 19 * ? *)"
  pipeline_arn        = var.addressing_codepipeline_arn
  iam_role_arn        = local.scheduler_role_arn
}

module "aws_ruby_node_pipeline" {
  source              = "./schedule"
  name                = "start-aws-ruby-node-pipeline"
  group_name          = local.group_name
  schedule_expression = "cron(33 14 19 * ? *)"
  pipeline_arn        = var.aws_ruby_node_codepipeline_arn
  iam_role_arn        = local.scheduler_role_arn
}

module "auth_server_pipeline" {
  source              = "./schedule"
  name                = "start-auth-server-pipeline"
  group_name          = local.group_name
  schedule_expression = "cron(33 15 23 * ? *)"
  pipeline_arn        = var.auth_server_codepipeline_arn
  iam_role_arn        = local.scheduler_role_arn
}

module "data_frontend_pipeline" {
  source              = "./schedule"
  name                = "start-data-frontend-pipeline"
  group_name          = local.group_name
  schedule_expression = "cron(03 10 23 * ? *)"
  pipeline_arn        = var.data_frontend_codepipeline_arn
  iam_role_arn        = local.scheduler_role_arn
}

module "fluentbit_pipeline" {
  source              = "./schedule"
  name                = "start-fluentbit-pipeline"
  group_name          = local.group_name
  schedule_expression = "cron(03 15 19 * ? *)"
  pipeline_arn        = var.fluentbit_codepipeline_arn
  iam_role_arn        = local.scheduler_role_arn
}

module "frontend_pipeline" {
  source              = "./schedule"
  name                = "start-frontend-pipeline"
  group_name          = local.group_name
  schedule_expression = "cron(03 14 23 * ? *)"
  pipeline_arn        = var.frontend_codepipeline_arn
  iam_role_arn        = local.scheduler_role_arn
}

module "reg_api_pipeline" {
  source              = "./schedule"
  name                = "start-reg-api-pipeline"
  group_name          = local.group_name
  schedule_expression = "cron(03 14 24 * ? *)"
  pipeline_arn        = var.reg_api_codepipeline_arn
  iam_role_arn        = local.scheduler_role_arn
}

module "warehouse_pipeline" {
  source              = "./schedule"
  name                = "start-warehouse-pipeline"
  group_name          = local.group_name
  schedule_expression = "cron(33 11 23 * ? *)"
  pipeline_arn        = var.warehouse_codepipeline_arn
  iam_role_arn        = local.scheduler_role_arn
}

module "postgres_pipeline" {
  source              = "./schedule"
  name                = "start-postgres-image-pipeline"
  group_name          = local.group_name
  schedule_expression = "cron(03 14 19 * ? *)"
  pipeline_arn        = var.postgres_codepipeline_arn
  iam_role_arn        = local.scheduler_role_arn
}

