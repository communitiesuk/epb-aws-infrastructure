data "aws_caller_identity" "current" {}

locals {
  ecr_arns = [
    "arn:aws:ecr:${var.region}:${var.account_ids["integration"]}:repository/${var.integration_prefix}-${var.app_ecr_name}/",
    "arn:aws:ecr:${var.region}:${var.account_ids["staging"]}:repository/${var.staging_prefix}-${var.app_ecr_name}/",
    "arn:aws:ecr:${var.region}:${var.account_ids["production"]}:repository/${var.production_prefix}-${var.app_ecr_name}/",
  ]
  codebuild_names = ["${var.project_name}-build-image", "${var.project_name}-deploy-image-integration", "${var.project_name}-run-integration-task", "${var.project_name}-deploy-image-staging", "${var.project_name}-deploy-image-production"]
}


module "codepipeline_iam" {
  source              = "../codepipeline_iam"
  project_name        = "fluentbit"
  region              = var.region
  ecr_arns            = local.ecr_arns
  codebuild_names     = local.codebuild_names
  etag_policy         = true
  artefact_bucket_arn = var.artefact_bucket_arn
}


module "codebuild_build_image" {
  source = "../codebuild_project"

  name               = "${var.project_name}-build-image"
  region             = var.region
  codebuild_role_arn = var.codebuild_role_arn
  build_image_uri    = var.aws_amd_codebuild_image
  buildspec_file     = "build_docker_image.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = data.aws_caller_identity.current.account_id },
  ]
}

module "codebuild_push_image_integration" {
  source = "../codebuild_project"

  name               = "${var.project_name}-deploy-image-integration"
  region             = var.region
  codebuild_role_arn = var.codebuild_role_arn
  build_image_uri    = var.aws_amd_codebuild_image
  buildspec_file     = "deploy_to_ecr.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["integration"] },
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["integration"]}.dkr.ecr.${var.region}.amazonaws.com/${var.integration_prefix}-${var.app_ecr_name}" },
    { name = "DOCKER_IMAGE", value = var.app_ecr_name },
    { name = "ECR_URL", value = "${var.account_ids["integration"]}.dkr.ecr.${var.region}.amazonaws.com/${var.integration_prefix}-${var.fluentbit_ecr_name}" },
    { name = "PREFIX", value = var.integration_prefix },
  ]
}

module "codebuild_run_integration_task" {
  source = "../codebuild_project"

  name               = "${var.project_name}-run-integration-task"
  region             = var.region
  codebuild_role_arn = var.codebuild_role_arn
  build_image_uri    = var.aws_amd_codebuild_image
  buildspec_file     = "run_integration_task.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["integration"] },
    { name = "PREFIX", value = var.integration_prefix },
  ]
}

module "codebuild_push_image_staging" {
  source = "../codebuild_project"

  name               = "${var.project_name}-deploy-image-staging"
  region             = var.region
  codebuild_role_arn = var.codebuild_role_arn
  build_image_uri    = var.aws_amd_codebuild_image
  buildspec_file     = "deploy_to_ecr.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["staging"] },
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["staging"]}.dkr.ecr.${var.region}.amazonaws.com/${var.staging_prefix}-${var.app_ecr_name}" },
    { name = "DOCKER_IMAGE", value = var.app_ecr_name },
    { name = "ECR_URL", value = "${var.account_ids["staging"]}.dkr.ecr.${var.region}.amazonaws.com/${var.staging_prefix}-${var.fluentbit_ecr_name}" },
    { name = "PREFIX", value = var.staging_prefix },
  ]
}

module "codebuild_push_image_production" {
  source = "../codebuild_project"

  name               = "${var.project_name}-deploy-image-production"
  region             = var.region
  codebuild_role_arn = var.codebuild_role_arn
  build_image_uri    = var.aws_amd_codebuild_image
  buildspec_file     = "deploy_to_ecr.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["production"] },
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["production"]}.dkr.ecr.${var.region}.amazonaws.com/${var.production_prefix}-${var.app_ecr_name}" },
    { name = "DOCKER_IMAGE", value = var.app_ecr_name },
    { name = "ECR_URL", value = "${var.account_ids["production"]}.dkr.ecr.${var.region}.amazonaws.com/${var.production_prefix}-${var.fluentbit_ecr_name}" },
    { name = "PREFIX", value = var.production_prefix },
  ]
}
