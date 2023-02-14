module "back-end" {
  source = "../modules/backend_module"
}

module "pipeline" {
  source            = "../modules/pipeline_module"
  github_repository = "epb-auth-server"
  project_name      = "epbr-auth-server"
  pipeline_name     = "epbr-auth-server-pipeline"
  github_branch     = "master"
}
