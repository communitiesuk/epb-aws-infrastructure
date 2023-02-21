module "back-end" {
  source = "../modules/backend_module"
}

module "shared_resources" {
  source = "../modules/shared_resources"
}


module "pipeline" {
  source                       = "../modules/pipeline_module"
  github_repository            = "epb-auth-server"
  project_name                 = "epbr-auth-server"
  pipeline_name                = "epbr-auth-server-pipeline"
  github_branch                = "master"
  app_ecr_name                 = "epb-intg-auth-service-ecr"
  codebuild_role_arn           = module.shared_resources.codebuild_role_arn
  codepipeline_bucket_arn      = module.shared_resources.codepipeline_bucket_arn
  codepipeline_bucket          = module.shared_resources.codepipeline_bucket_bucket
  communitiesuk_connection_arn = module.shared_resources.communitiesuk_connection_arn
  account_ids                  = var.account_ids
  ecs_cluster_name             = "epb-intg-auth-service-cluster"
  ecs_service_name             = "epb-intg-auth-service"
}
