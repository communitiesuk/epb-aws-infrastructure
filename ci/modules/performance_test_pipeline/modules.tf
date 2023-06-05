module "codebuild_performance_test" {
  source                = "../codebuild_project"
  codebuild_role_arn    = var.codebuild_role_arn
  name                  = "${var.project_name}-codebuild-performance-test"
  build_image_uri       = var.aws_codebuild_image
  buildspec_file        = "buildspec_aws.yml"
  environment_variables = []
  region                = var.region
}