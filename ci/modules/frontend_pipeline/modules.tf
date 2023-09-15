data "aws_caller_identity" "current" {}

module "codebuild_run_app_test" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-run-test"
  build_image_uri    = var.codebuild_image_ecr_url
  buildspec_file     = "buildspec/run_app_tests.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = data.aws_caller_identity.current.account_id },
    { name = "STAGE", value = "integration" },
  ]
  region = var.region
}

module "codebuild_build_app_image" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-build-image"
  buildspec_file     = "buildspec/build_paketo_image.yml"
  build_image_uri    = var.codebuild_image_ecr_url
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
  build_image_uri    = var.aws_codebuild_image
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
  build_image_uri    = var.aws_codebuild_image
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

module "codebuild_frontend_smoke_test" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-frontend-smoke-test"
  build_image_uri    = var.codebuild_image_ecr_url
  buildspec_file     = "buildspec/run_smoke_test_in_code_build.yml"
  environment_variables = [
    { name = "cypress_get_service_en_integration", value = "${var.static_start_page_url}/getting-a-new-energy-certificate.html" },
    { name = "cypress_get_domain_integration", value = "https://getting-new-energy-certificate-integration.${var.front_end_domain}" },
    { name = "cypress_get_service_cy_integration", value = "${var.static_start_page_url}/sicrhau-tystysgrif-ynni-newydd.html" },
    { name = "cypress_find_service_en_integration", value = "${var.static_start_page_url}/find-an-energy-certificate.html" },
    { name = "cypress_find_domain_integration", value = "https://find-energy-certificate-integration.${var.front_end_domain}" },
    { name = "cypress_find_service_cy_integration", value = "${var.static_start_page_url}/chwiliwch-am-dystysgrif-ynni.html" }
  ]
  region = var.region
}

module "codebuild_deploy_production" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-deploy-production"
  build_image_uri    = var.aws_codebuild_image
  buildspec_file     = "buildspec/deploy_to_cluster.yml"
  environment_variables = [
    { name = "AWS_DEFAULT_REGION", value = var.region },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["production"] },
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["production"]}.dkr.ecr.${var.region}.amazonaws.com/${var.production_prefix}-${var.app_ecr_name}" },
    { name = "CLUSTER_NAME", value = "${var.production_prefix}-${var.ecs_cluster_name}" },
    { name = "SERVICE_NAME", value = "${var.production_prefix}-${var.ecs_service_name}" },
    { name = "PREFIX", value = var.production_prefix },
  ]
  region = var.region
}