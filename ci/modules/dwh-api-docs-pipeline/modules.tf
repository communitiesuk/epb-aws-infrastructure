module "codebuild_build_push_repo_intg" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-deploy-integration"
  build_image_uri    = "aws/codebuild/standard:7.0"
  buildspec_file     = "${var.configuration}/build_api_docs_and_push_to_aws.yml"
  environment_variables = [
    { name = "ENV", value = "intg" },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["integration"] },
  ]
  region = var.region
}

module "codebuild_build_push_repo_stag" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-deploy-staging"
  build_image_uri    = "aws/codebuild/standard:7.0"
  buildspec_file     = "${var.configuration}/build_api_docs_and_push_to_aws.yml"
  environment_variables = [
    { name = "ENV", value = "stag" },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["staging"] },
  ]
  region = var.region
}

module "codebuild_build_push_repo_prod" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "${var.project_name}-deploy-production"
  build_image_uri    = "aws/codebuild/standard:7.0"
  buildspec_file     = "${var.configuration}/build_api_docs_and_push_to_aws.yml"
  environment_variables = [
    { name = "ENV", value = "prod" },
    { name = "AWS_ACCOUNT_ID", value = var.account_ids["production"] },
  ]
  region = var.region
}
