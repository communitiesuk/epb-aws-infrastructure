module "artefact" {
  source = "./modules/artifact_bucket"
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
  source                  = "./modules/service_codebuild_role"
  codepipeline_bucket_arn = module.artefact.codepipeline_bucket_arn
  cross_account_role_arns = var.cross_account_role_arns
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  region                  = var.region
}


module "app_test_image_pipeline" {
  artefact_bucket         = module.artefact.codepipeline_bucket
  artefact_bucket_arn     = module.artefact.codepipeline_bucket_arn
  configuration           = "aws-ruby-node"
  source                  = "./modules/build_test_image_pipeline"
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  github_repository       = "epb-docker-images"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  region                  = var.region
  project_name            = "epbr-aws-ruby-node-image"
}

module "postgres_test_image_pipeline" {
  artefact_bucket         = module.artefact.codepipeline_bucket
  artefact_bucket_arn     = module.artefact.codepipeline_bucket_arn
  configuration           = "postgres"
  source                  = "./modules/build_test_image_pipeline"
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  github_repository       = "epb-docker-images"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  project_name            = "epbr-postgres-image"
  region                  = var.region
}

module "auth-server-pipeline" {
  source                  = "./modules/auth_server_pipeline"
  aws_arm_codebuild_image = var.aws_arm_codebuild_image
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-auth-server-pipeline"
  github_repository       = "epb-auth-server"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids             = var.account_ids
  ecs_cluster_name        = "epb-intg-auth-service-cluster"
  ecs_service_name        = "epb-intg-auth-service"
  app_ecr_name            = "epb-intg-auth-service-ecr"
  project_name            = "epbr-auth-server"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  postgres_image_ecr_url  = module.postgres_test_image_pipeline.image_repository_url
  region                  = var.region
}

module "register-api-pipeline" {
  source                  = "./modules/register_api_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-register-api-pipeline"
  github_repository       = "epb-register-api"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids             = var.account_ids
  ecs_cluster_name        = "epb-intg-api-service-cluster"
  ecs_service_name        = "epb-intg-api-service"
  app_ecr_name            = "epb-intg-api-service-ecr"
  project_name            = "epbr-register-api"
  ecs_sidekiq_cluster_name = "epb-intg-sidekiq-cluster"
  ecs_sidekiq_service_name = "epb-intg-sidekiq"
  docker_image_app_name    = "ebpr-register-api-image"
  docker_image_sidekiq_name = "epb-register-api-worker"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  postgres_image_ecr_url  = module.postgres_test_image_pipeline.image_repository_url
  region                  = var.region
  aws_arm_codebuild_image = var.aws_arm_codebuild_image
  sidekiq_ecr_name        = "epb-intg-sidekiq-ecr"
  smoketests_repository   = var.smoketests_repository
  smoketests_branch       = var.smoketests_branch
}

module "frontend-pipeline" {
  source                  = "./modules/frontend_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-frontend-pipeline"
  github_repository       = "epb-frontend"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids             = var.account_ids
  ecs_cluster_name        = "epb-intg-frontend-cluster"
  ecs_service_name        = "epb-intg-frontend"
  app_ecr_name            = "epb-intg-frontend-ecr"
  project_name            = "epbr-frontend"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  region                  = var.region
  aws_arm_codebuild_image = var.aws_arm_codebuild_image
  smoketests_repository   = var.smoketests_repository
  smoketests_branch       = var.smoketests_branch
}

module "data_warehouse-pipeline" {
  source                  = "./modules/data_warehouse_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-data-warehouse-pipeline"
  github_repository       = "epb-data-warehouse"
  github_branch           = "main"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids             = var.account_ids
  ecs_cluster_name        = "epb-intg-warehouse-cluster"
  ecs_service_name        = "epb-intg-warehouse"
  app_ecr_name            = "epb-intg-warehouse-ecr"
  project_name            = "epbr-data-warehouse"
  codebuild_image_ecr_url = module.app_test_image_pipeline.image_repository_url
  postgres_image_ecr_url  = module.postgres_test_image_pipeline.image_repository_url
  region                  = var.region
  aws_arm_codebuild_image = var.aws_arm_codebuild_image
}

module "toggles-pipeline" {
  source                  = "./modules/toggles_pipeline"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name           = "epbr-toggles-pipeline"
  github_repository       = "epb-toggles"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids             = var.account_ids
  ecs_cluster_name        = "epb-intg-toggles-cluster"
  ecs_service_name        = "epb-intg-toggles"
  app_ecr_name            = "epb-intg-toggles-ecr"
  project_name            = "epbr-toggles"
  region                  = var.region
  aws_arm_codebuild_image = var.aws_arm_codebuild_image
}