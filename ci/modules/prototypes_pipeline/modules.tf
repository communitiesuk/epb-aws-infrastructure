module "codebuild_build_app_image" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-app-image"
  buildspec_file     = "buildspec/build_push_docker_image.yml"
  build_image_uri    = var.codebuild_image_ecr_url
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.dev_account_id },
    { name = "DOCKER_IMAGE", value = var.app_image_name },
    { name = "DOCKER_IMAGE_URI", value = "${var.dev_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.developer_prefix}-${var.app_ecr_name}" },
  ]
  region = var.region
}

module "codebuild_deploy" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-deploy"
  build_image_uri    = var.aws_codebuild_image
  buildspec_file     = "buildspec/restart_cluster.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.dev_account_id },
    { name = "DOCKER_IMAGE", value = var.app_image_name },
    { name = "CLUSTER_NAME", value = "${var.developer_prefix}-${var.ecs_cluster_name}" },
    { name = "SERVICE_NAME", value = "${var.developer_prefix}-${var.ecs_service_name}" },
  ]
  region = var.region
}