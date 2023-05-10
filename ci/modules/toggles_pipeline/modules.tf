module "codebuild_build_app_image" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-build-image"
  buildspec_file     = "buildspec/build_docker_image.yml"
  codebuild_environment_type   = "ARM_CONTAINER"
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
  codebuild_environment_type   = "ARM_CONTAINER"
  build_image_uri    = var.aws_arm_codebuild_image
  buildspec_file     = "buildspec/deploy_to_cluster.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["integration"] },
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["integration"]}.dkr.ecr.${var.region}.amazonaws.com/${var.integration_prefix}-${var.app_ecr_name}" },
    { name = "CLUSTER_NAME", value = "${var.integration_prefix}-${var.ecs_cluster_name}" },
    { name = "SERVICE_NAME", value = "${var.integration_prefix}-${var.ecs_service_name}" },
  ]
  region = var.region
}

module "codebuild_deploy_staging" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-deploy-staging"
  codebuild_environment_type   = "ARM_CONTAINER"
  build_image_uri    = var.aws_arm_codebuild_image
  buildspec_file     = "buildspec/deploy_to_cluster.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["staging"] },
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["staging"]}.dkr.ecr.${var.region}.amazonaws.com/${var.staging_prefix}-${var.app_ecr_name}" },
    { name = "CLUSTER_NAME", value = "${var.staging_prefix}-${var.ecs_cluster_name}" },
    { name = "SERVICE_NAME", value = "${var.staging_prefix}-${var.ecs_service_name}" },
  ]
  region = var.region
}