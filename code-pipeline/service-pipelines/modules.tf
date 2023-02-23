
module "artefact" {
  source = "../modules/artifact_bucket"
}

module "codestar_connection" {
  source = "../modules/codestar_connection"
}

module "codepipeline_role" {
  source = "../modules/codepipeline_role"
  codepipeline_bucket = module.artefact.codepipeline_bucket_bucket
  codepipeline_bucket_arn = module.artefact.codepipeline_bucket_arn
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
}

module "codebuild_role" {
  source = "../modules/service_codebuild_role"
  codepipeline_bucket = module.artefact.codepipeline_bucket_bucket
  codepipeline_bucket_arn = module.artefact.codepipeline_bucket_arn
  cross_account_role_arns = var.cross_account_role_arns
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
}


#TODO Refactor so that this is 2 codebuild pipelines from one module
module "build_test_image_pipelines" {
  source = "../modules/build_test_image_pipeline"
  codepipeline_arn = module.codepipeline_role.aws_codepipeline_arn
  github_repository  = "epb-docker-images"
  github_branch = "master"
  github_organisation = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  region = "eu-west-2"
  project_name                 = "epbr-codebuild-image"
}


module "auth-server-pipeline" {
  source = "../modules/auth_server_pipeline"
  codepipeline_bucket_arn = module.artefact.codepipeline_bucket_arn
  codepipeline_bucket = module.artefact.codepipeline_bucket_bucket
  codepipeline_arn = module.codepipeline_role.aws_codepipeline_arn
  codebuild_role_arn = module.codebuild_role.aws_codebuild_role_arn
  pipeline_name = "epbr-auth-server-pipeline"
  github_repository  = "epb-auth-server"
  github_branch = "master"
  github_organisation = var.github_organisation
  codestar_connection_arn = module.codestar_connection.codestar_connection_arn
  account_ids                  = var.account_ids
  ecs_cluster_name             = "epb-intg-auth-service-cluster"
  ecs_service_name             = "epb-intg-auth-service"
  app_ecr_name                 = "epb-intg-auth-service-ecr"
  project_name                 = "epbr-auth-server"
  codebuild_image_ecr_url      = module.build_test_image_pipelines.image_repositories["epbr-codebuild-image"]
  postgres_image_ecr_url       = module.build_test_image_pipelines.image_repositories["epbr-postgres"]

}

