data "aws_caller_identity" "current" {}

module "codepipeline_iam" {
  source                  = "../codepipeline_iam"
  project_name            = "view-models"
  region                  = var.region
  codestar_connection_arn = var.codestar_connection_arn
  codebuild_names         = ["${var.project_name}-codebuild-run-test"]
  artefact_bucket_arn     = var.artefact_bucket_arn
}

module "codebuild_run_app_test" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-run-test"
  build_image_uri    = var.codebuild_image_ecr_url
  buildspec_file     = ".buildspec.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = data.aws_caller_identity.current.account_id },
  ]
  region = var.region
}
