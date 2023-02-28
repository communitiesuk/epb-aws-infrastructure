module "artefact" {
  source = "../modules/artifact_bucket"
}

module "codestar_connection" {
  source = "../modules/codestar_connection"
}

module "codepipeline_role" {
  source                  = "../modules/codepipeline_role"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_bucket_arn = module.artefact.codepipeline_bucket_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
}

module "codebuild_role" {
  source                  = "../modules/service_codebuild_role"
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_bucket_arn = module.artefact.codepipeline_bucket_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  cross_account_role_arns = var.cross_account_role_arns
}

module "build_test_image_pipeline" {
  source                  = "../modules/build_test_image_pipeline"
  artefact_bucket         = module.artefact.codepipeline_bucket
  artefact_bucket_arn     = module.artefact.codepipeline_bucket_arn
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  configuration           = "codebuild-cloudfoundry"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  github_repository       = "epb-docker-images"
  project_name            = "epbr-codebuild-image"
  region                  = "eu-west-2"
}

module "postgres_test_image_pipeline" {
  source                  = "../modules/build_test_image_pipeline"
  artefact_bucket         = module.artefact.codepipeline_bucket
  artefact_bucket_arn     = module.artefact.codepipeline_bucket_arn
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  configuration           = "postgres"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  github_repository       = "epb-docker-images"
  project_name            = "epbr-postgres-image"
  region                  = "eu-west-2"
}

module "auth-server-pipeline" {
  source                  = "../modules/auth_server_pipeline"
  account_ids             = var.account_ids
  app_ecr_name            = "epb-intg-auth-service-ecr"
  codebuild_image_ecr_url = module.build_test_image_pipeline.image_repository_url
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_bucket_arn = module.artefact.codepipeline_bucket_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  ecs_cluster_name        = "epb-intg-auth-service-cluster"
  ecs_service_name        = "epb-intg-auth-service"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  github_repository       = "epb-auth-server"
  pipeline_name           = "epbr-auth-server-pipeline"
  postgres_image_ecr_url  = module.postgres_test_image_pipeline.image_repository_url
  project_name            = "epbr-auth-server"
}

module "register-api-pipeline" {
  source = "../modules/register_api_pipeline"
  account_ids             = var.account_ids
  app_ecr_name            = "epb-intg-api-service-ecr"
  codebuild_image_ecr_url = module.build_test_image_pipeline.image_repository_url
  codebuild_role_arn      = module.codebuild_role.aws_codebuild_role_arn #?
  codepipeline_arn        = module.codepipeline_role.aws_codepipeline_arn #?
  codepipeline_bucket     = module.artefact.codepipeline_bucket
  codepipeline_bucket_arn = module.artefact.codepipeline_bucket_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  ecs_cluster_name        = "epb-intg-api-service-cluster"
  ecs_service_name        = "epb-intg-api-service"
  github_branch           = "master"
  github_organisation     = var.github_organisation
  github_repository       = "epb-register-api"
  pipeline_name           = "epbr-register-api-pipeline"
  postgres_image_ecr_url  = module.postgres_test_image_pipeline.image_repository_url
  project_name            = "epbr-register-api"
}
