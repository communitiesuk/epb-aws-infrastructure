
data "aws_caller_identity" "current" {}

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
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["integration"]}.dkr.ecr.${var.region}.amazonaws.com/${var.app_ecr_name}" },
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
    { name = "DOCKER_IMAGE_URI", value = "${var.account_ids["integration"]}.dkr.ecr.${var.region}.amazonaws.com/${var.app_ecr_name}" },
    { name = "CLUSTER_NAME", value = var.ecs_cluster_name },
    { name = "SERVICE_NAME", value = var.ecs_service_name },
  ]
  region = var.region
}

module "codebuild_frontend_smoke_test" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-codebuild-frontend-smoke-test"
  environment_type   = "LINUX_CONTAINER"
  build_image_uri    = var.codebuild_image_ecr_url
  buildspec_file     = "buildspec/run_smoke_test_in_code_build.yml"
  environment_variables = [
    { name  = "cypress_get_service_en_integration", value = "http://epb-static-start-pages-integration.s3-website.eu-west-2.amazonaws.com/getting-a-new-energy-certificate.html" },
    { name = "cypress_get_domain_integration", value = "https://getting-new-energy-certificate-integration.centraldatastore.net" },
    { name = "cypress_get_service_cy_integration", value = "http://epb-static-start-pages-integration.s3-website.eu-west-2.amazonaws.com/sicrhau-tystysgrif-ynni-newydd.html" },
    { name = "cypress_find_service_en_integration", value = "http://epb-static-start-pages-integration.s3-website.eu-west-2.amazonaws.com/find-an-energy-certificate.html" },
    { name = "cypress_find_domain_integration", value = "https://find-energy-certificate-integration.centraldatastore.net" },
    { name = "cypress_find_service_cy_integration", value = "http://epb-static-start-pages-integration.s3-website.eu-west-2.amazonaws.com/chwiliwch-am-dystysgrif-ynni.html" }
  ]
  region = var.region
}