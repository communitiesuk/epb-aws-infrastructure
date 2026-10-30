locals {
  codebuild_names = [
    "${var.project_name}-codebuild-run-test",
    "${var.project_name}-codebuild-deploy-integration",
    "${var.project_name}-codebuild-deploy-staging",
    "${var.project_name}-codebuild-deploy-production"
  ]
}

module "codepipeline_iam" {
  source                  = "../codepipeline_iam"
  project_name            = "data-warehouse-glue"
  region                  = var.region
  ecr_arns                = null
  codestar_connection_arn = var.codestar_connection_arn
  codebuild_names         = local.codebuild_names
  artefact_bucket_arn     = var.artefact_bucket_arn
}


module "codebuild_run_test" {
  source                = "../codebuild_project"
  codebuild_role_arn    = var.codebuild_role_arn
  name                  = "${var.project_name}-codebuild-run-test"
  build_image_uri       = var.aws_codebuild_image
  buildspec_file        = "buildspec/run_tests.yml"
  environment_variables = []
}

module "codebuild_deploy_integration" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-deploy-integration"
  build_image_uri    = var.aws_codebuild_image
  buildspec_file     = "buildspec/deploy_to_s3.yml"
  environment_variables = [
    { name = "S3_BUCKET_NAME", value = "${var.integration_prefix}-data-lake" },
    { name = "TARGET_PREFIX", value = "etl_scripts" },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["integration"] }
  ]
}

module "codebuild_deploy_staging" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-deploy-staging"
  build_image_uri    = var.aws_codebuild_image
  buildspec_file     = "buildspec/deploy_to_s3.yml"
  environment_variables = [
    { name = "S3_BUCKET_NAME", value = "${var.staging_prefix}-data-lake" },
    { name = "TARGET_PREFIX", value = "etl_scripts" },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["staging"] }
  ]
}


module "codebuild_deploy_production" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-deploy-production"
  build_image_uri    = var.aws_codebuild_image
  buildspec_file     = "buildspec/deploy_to_s3.yml"
  environment_variables = [
    { name = "S3_BUCKET_NAME", value = "${var.production_prefix}-data-lake" },
    { name = "TARGET_PREFIX", value = "etl_scripts" },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["production"] }
  ]
}
