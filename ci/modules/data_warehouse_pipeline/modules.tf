data "aws_caller_identity" "current" {}

locals {
  integration_prefix = "epb-intg"
  staging_prefix = "epb-stag"
}

module "codebuild_run_app_test" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-run-test"
  build_image_uri    = var.codebuild_image_ecr_url
  environment_type   = "LINUX_CONTAINER"
  buildspec_file     = "buildspec/run_app_tests.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = data.aws_caller_identity.current.account_id },
    { name = "STAGE", value = "integration" },
    { name = "POSTGRES_IMAGE_URL", value = var.postgres_image_ecr_url },

  ]
  region = var.region
}

module "codebuild_build_app_image" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-build-image"
  buildspec_file     = "buildspec/build_docker_image.yml"
  environment_type   = "ARM_CONTAINER"
  build_image_uri    = var.aws_arm_codebuild_image
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["integration"] },
  ]
  region = var.region
}

module "codebuild_deploy_integration" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-deploy-integration"
  environment_type   = "ARM_CONTAINER"
  build_image_uri    = var.aws_arm_codebuild_image
  buildspec_file     = "buildspec/deploy_to_cluster.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["integration"] },
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["integration"]}.dkr.ecr.${var.region}.amazonaws.com/${local.integration_prefix}-${var.app_ecr_name}" },
    { name = "CLUSTER_NAME", value = "${local.integration_prefix}-${var.ecs_cluster_name}" },
    { name = "SERVICE_NAME", value = "${local.integration_prefix}-${var.ecs_service_name}" },
  ]
  region = var.region
}

module "codebuild_deploy_staging" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-deploy-staging"
  environment_type   = "ARM_CONTAINER"
  build_image_uri    = var.aws_arm_codebuild_image
  buildspec_file     = "buildspec/deploy_to_cluster.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["staging"] },
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["staging"]}.dkr.ecr.${var.region}.amazonaws.com/${local.staging_prefix}-${var.app_ecr_name}" },
    { name = "CLUSTER_NAME", value = "${local.staging_prefix}-${var.ecs_cluster_name}" },
    { name = "SERVICE_NAME", value = "${local.staging_prefix}-${var.ecs_service_name}" },
  ]
  region = var.region
}