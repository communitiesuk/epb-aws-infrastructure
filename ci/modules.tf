module "account_security" {
  source = "./modules/account_security"
}

module "artefact" {
  source = "./modules/artifact_bucket"
  region = var.region
}

module "performance_reports" {
  source = "./modules/performance_test_report_bucket"
  region = var.region
}

module "codestar_connection" {
  source = "./modules/codestar_connection"
  region = var.region
}

module "codepipeline_role" {
  source = "./modules/codepipeline_role"
  region = var.region
}

module "codebuild_role" {
  source                         = "./modules/service_codebuild_role"
  codepipeline_bucket_arn        = module.artefact.codepipeline_bucket_arn
  performance_reports_bucket_arn = module.performance_reports.codepipeline_bucket_arn
  cross_account_role_arns        = var.cross_account_role_arns
  codestar_connection_arn        = module.codestar_connection.codestar_connection_arn
  region                         = var.region
  s3_buckets_to_access           = [var.tech_docs_bucket_repo, var.api_docs_bucket]
}

module "app_test_image_pipeline" {
  source = "./modules/build_test_image_pipeline"

  artefact_bucket         = module.artefact.codepipeline_bucket
  artefact_bucket_arn     = module.artefact.codepipeline_bucket_arn
  build_spec_file         = "aws-ruby-node/buildspec_aws.yml"
  configuration           = "aws-ruby-node"
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  github_repository       = "epb-docker-images"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  region                  = var.region
  project_name            = "epbr-aws-ruby-node-image"
}

module "postgres_test_image_pipeline" {
  source                = "./modules/postgres_image_pipeline"
  artefact_bucket       = module.artefact.codepipeline_bucket
  artefact_bucket_arn   = module.artefact.codepipeline_bucket_arn
  codepipeline_role_arn = module.codepipeline_role.aws_codepipeline_role_arn
  pipeline_name         = "epbr-postgres-image-pipeline"
  project_name          = "epbr-postgres-image"
  region                = var.region

}

module "auth-server-pipeline" {
  source                  = "./modules/auth_server_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-auth-server-pipeline"
  github_repository       = "epb-auth-server"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  integration_prefix      = var.integration_prefix
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids             = var.account_ids
  ecs_cluster_name        = "auth-cluster"
  ecs_service_name        = "auth"
  app_ecr_name            = "auth-ecr"
  project_name            = "epbr-auth-server"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  postgres_image_ecr_url  = module.postgres_test_image_pipeline.image_repository_url
  region                  = var.region
  aws_codebuild_image     = var.aws_amd_codebuild_image
  staging_prefix          = var.staging_prefix
  production_prefix       = var.production_prefix
}

module "auth-tools-pipeline" {
  source                  = "./modules/auth_tools_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-auth-tools-pipeline"
  github_repository       = "epb-auth-tools"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  project_name            = "epbr-auth-tools"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  region                  = var.region
}

module "register-api-pipeline" {
  source                      = "./modules/register_api_pipeline"
  codepipeline_bucket         = module.artefact.codepipeline_bucket
  codepipeline_role_arn       = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn          = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name               = "epbr-register-api-pipeline"
  github_repository           = "epb-register-api"
  github_branch               = "master"
  github_organisation         = var.github_organisation
  integration_prefix          = var.integration_prefix
  codestar_connection_arn     = module.codestar_connection.codestar_connection_arn
  account_ids                 = var.account_ids
  ecs_cluster_name            = "reg-api-cluster"
  ecs_service_name            = "reg-api"
  app_ecr_name                = "reg-api-ecr"
  project_name                = "epbr-register-api"
  app_image_name              = "ebpr-register-api-image"
  codebuild_image_ecr_url     = module.app_test_image_pipeline.image_repository_url
  postgres_image_ecr_url      = module.postgres_test_image_pipeline.image_repository_url
  region                      = var.region
  aws_codebuild_image         = var.aws_amd_codebuild_image
  performance_test_repository = var.performance_test_repository
  performance_test_branch     = var.performance_test_branch
  smoketests_repository       = var.smoketests_repository
  smoketests_branch           = var.smoketests_branch
  staging_prefix              = var.staging_prefix
  production_prefix           = var.production_prefix
  static_start_page_url       = var.static_start_page_url
  front_end_domain            = var.front_end_domain
}

module "performance_test_pipeline" {
  source                      = "./modules/performance_test_pipeline"
  codepipeline_bucket         = module.artefact.codepipeline_bucket
  codepipeline_role_arn       = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn          = module.codebuild_role.aws_codebuild_role_arn
  project_name                = "epbr-performance-test"
  pipeline_name               = "epbr-performance-test-pipeline"
  github_organisation         = var.github_organisation
  codestar_connection_arn     = module.codestar_connection.codestar_connection_arn
  region                      = var.region
  aws_codebuild_image         = var.aws_amd_codebuild_image
  performance_test_repository = var.performance_test_repository
  performance_test_branch     = var.performance_test_branch
}

module "frontend-pipeline" {
  source                  = "./modules/frontend_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-frontend-pipeline"
  github_repository       = "epb-frontend"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  integration_prefix      = var.integration_prefix
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids             = var.account_ids
  ecs_cluster_name        = "frontend-cluster"
  ecs_service_name        = "frontend"
  app_ecr_name            = "frontend-ecr"
  project_name            = "epbr-frontend"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  region                  = var.region
  aws_codebuild_image     = var.aws_amd_codebuild_image
  smoketests_repository   = var.smoketests_repository
  smoketests_branch       = var.smoketests_branch
  staging_prefix          = var.staging_prefix
  production_prefix       = var.production_prefix
  static_start_page_url   = var.static_start_page_url
  front_end_domain        = var.front_end_domain
}

module "data_warehouse-pipeline" {
  source                  = "./modules/data_warehouse_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-data-warehouse-pipeline"
  github_repository       = "epb-data-warehouse"
  github_branch           = "main"
  github_organisation     = var.github_organisation
  integration_prefix      = var.integration_prefix
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids             = var.account_ids
  ecs_cluster_name        = "warehouse-cluster"
  ecs_service_name        = "warehouse"
  ecs_api_cluster_name    = "warehouse-api-cluster"
  ecs_api_service_name    = "warehouse-api"
  app_ecr_name            = "warehouse-ecr"
  api_ecr_name            = "warehouse-api-ecr"
  project_name            = "epbr-data-warehouse"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  postgres_image_ecr_url  = module.postgres_test_image_pipeline.image_repository_url
  region                  = var.region
  aws_codebuild_image     = var.aws_amd_codebuild_image
  staging_prefix          = var.staging_prefix
  production_prefix       = var.production_prefix
}

module "toggles-pipeline" {
  source                  = "./modules/toggles_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-toggles-pipeline"
  github_repository       = "epb-toggles"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  integration_prefix      = var.integration_prefix
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids             = var.account_ids
  ecs_cluster_name        = "toggles-cluster"
  ecs_service_name        = "toggles"
  app_ecr_name            = "toggles-ecr"
  project_name            = "epbr-toggles"
  region                  = var.region
  aws_codebuild_image     = var.aws_amd_codebuild_image
  staging_prefix          = var.staging_prefix
  production_prefix       = var.production_prefix
}

module "fluentbit_pipeline" {
  source                  = "./modules/fluentbit_pipeline"
  artefact_bucket         = module.artefact.codepipeline_bucket
  artefact_bucket_arn     = module.artefact.codepipeline_bucket_arn
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "fluentbit-pipeline"
  account_ids             = var.account_ids
  fluentbit_ecr_name      = "fluentbit"
  project_name            = "fluentbit"
  region                  = var.region
  aws_amd_codebuild_image = var.aws_amd_codebuild_image
  integration_prefix      = var.integration_prefix
  staging_prefix          = var.staging_prefix
  production_prefix       = var.production_prefix
}

module "restart_ecs_tasks_pipeline" {
  source                = "./modules/restart_tasks_pipeline"
  codepipeline_bucket   = module.artefact.codepipeline_bucket
  codepipeline_role_arn = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn    = module.codebuild_role.aws_codebuild_role_arn
  aws_codebuild_image   = var.aws_amd_codebuild_image
  pipeline_name         = "restart-ecs-tasks-pipeline"
  account_ids           = var.account_ids
  project_name          = "epbr-ecs-restart-tasks"
  region                = var.region
  integration_prefix    = var.integration_prefix
  staging_prefix        = var.staging_prefix
  production_prefix     = var.production_prefix
}

module "cc-tray" {
  source = "./modules/cc_tray"
  region = var.region
}

module "tech_docs_pipeline" {
  artefact_bucket         = module.artefact.codepipeline_bucket
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  github_branch           = "master"
  github_repository       = "epb-tech-docs"
  github_organisation     = var.github_organisation
  region                  = var.region
  repo_bucket_name        = var.tech_docs_bucket_repo
  source                  = "./modules/tech-docs-pipeline"
  dev_account_id          = var.account_ids["developer"]
}

module "api_docs_pipeline" {
  source                  = "./modules/api-docs-pipeline"
  artefact_bucket         = module.artefact.codepipeline_bucket
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  github_branch           = "master"
  github_repository       = "epb-register-api"
  github_organisation     = var.github_organisation
  region                  = var.region
  repo_bucket_name        = var.api_docs_bucket
  dev_account_id          = var.account_ids["developer"]
}

module "prototypes_pipeline" {
  artefact_bucket         = module.artefact.codepipeline_bucket
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  github_branch           = "master"
  github_repository       = "epb-prototypes"
  github_organisation     = var.github_organisation
  region                  = var.region
  source                  = "./modules/prototypes_pipeline"
  dev_account_id          = var.account_ids["developer"]
  ecs_cluster_name        = "prototypes-cluster"
  ecs_service_name        = "prototypes"
  app_ecr_name            = "prototypes-ecr"
  aws_codebuild_image     = var.aws_amd_codebuild_image
  app_image_name          = "prototypes-image"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  developer_prefix        = var.developer_prefix
}

module "view-models-pipeline" {
  source                  = "./modules/view_models_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-view-models-pipeline"
  github_repository       = "epb-view-models"
  github_branch           = "main"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  project_name            = "epbr-view-models"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  region                  = var.region
}

module "address-base-updater-pipeline" {
  source                  = "./modules/address_base_updater_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_role_arn   = module.codepipeline_role.aws_codepipeline_role_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  integration_prefix      = var.integration_prefix
  staging_prefix          = var.staging_prefix
  production_prefix       = var.production_prefix
  pipeline_name           = "epbr-address-base-updater-pipeline"
  github_repository       = "epb-update-address-base"
  github_branch           = "main"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  project_name            = "epbr-address-base-updater"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  region                  = var.region
  account_ids             = var.account_ids
  app_ecr_name            = "address-base-updater-ecr"
  aws_codebuild_image     = var.aws_amd_codebuild_image
  postgres_image_ecr_url  = module.postgres_test_image_pipeline.image_repository_url
}

module "logging" {
  source = "./logging"
  region = var.region
}

module "alerts" {
  source = "./alerts"

  region                     = var.region
  environment                = "ci-cd"
  main_slack_webhook_url     = var.parameters["EPB_TEAM_MAIN_SLACK_URL"]
  cloudtrail_log_group_name  = module.logging.cloudtrail_log_group_name
}

module "parameters" {
  source = "./parameter_store"
  parameters = {
    EPB_TEAM_MAIN_SLACK_URL : {
      type  = "SecureString"
      value = var.parameters["EPB_TEAM_MAIN_SLACK_URL"]
    }
  }
}