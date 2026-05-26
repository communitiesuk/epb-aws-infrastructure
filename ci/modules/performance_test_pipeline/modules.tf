module "codepipeline_iam" {
  source                  = "../codepipeline_iam"
  project_name            = "performance-test"
  region                  = var.region
  codestar_connection_arn = var.codestar_connection_arn
  codebuild_names         = ["${var.project_name}-codebuild-performance-test-stag", "${var.project_name}-codebuild-performance-test-prod"]
  artefact_bucket_arn     = var.artefact_bucket_arn
}


module "codebuild_performance_test" {
  source                = "../codebuild_project"
  codebuild_role_arn    = var.codebuild_role_arn
  name                  = "${var.project_name}-codebuild-performance-test-stag"
  build_image_uri       = var.aws_codebuild_image
  buildspec_file        = "buildspec_aws.yml"
  environment_variables = []
  region                = var.region
}

module "codebuild_performance_test_production" {
  source                = "../codebuild_project"
  codebuild_role_arn    = var.codebuild_role_arn
  name                  = "${var.project_name}-codebuild-performance-test-prod"
  build_image_uri       = var.aws_codebuild_image
  buildspec_file        = "buildspec_aws_production.yml"
  environment_variables = []
  region                = var.region
}
