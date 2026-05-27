locals {
  codebuild_names = ["${var.project_name}-codebuild-integration", "${var.project_name}-codebuild-staging", "${var.project_name}-codebuild-production"]
}

module "codepipeline_iam" {
  source              = "../codepipeline_iam"
  project_name        = "restart-tasks"
  region              = var.region
  codebuild_names     = local.codebuild_names
  artefact_bucket_arn = var.artefact_bucket_arn
}


module "codebuild_restart_integration" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-integration"
  build_image_uri    = var.aws_codebuild_image
  buildspec_file     = "restart_ecs_tasks.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["integration"] },
    { name = "PREFIX", value = var.integration_prefix }
  ]
  region = var.region
}

module "codebuild_restart_staging" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-staging"
  build_image_uri    = var.aws_codebuild_image
  buildspec_file     = "restart_ecs_tasks.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["staging"] },
    { name = "PREFIX", value = var.staging_prefix }
  ]
  region = var.region
}

module "codebuild_restart_production" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-production"
  build_image_uri    = var.aws_codebuild_image
  buildspec_file     = "restart_ecs_tasks.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["production"] },
    { name = "PREFIX", value = var.production_prefix }
  ]
  region = var.region
}
