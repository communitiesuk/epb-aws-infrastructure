module "codebuild_build_push_repo" {
  source             = "../codebuild_project"
  codebuild_role_arn = var.codebuild_role_arn
  name               = "epbr-codebuild-${var.project_name}"
  build_image_uri    = "aws/codebuild/standard:7.0"
  buildspec_file     = "${var.configuration}/build_api_docs_and_push_to_aws.yml"
  environment_variables = [
    { name = "BUCKET_NAME", value = var.repo_bucket_name },
    { name = "AWS_ACCOUNT_ID", value = var.dev_account_id },
  ]
  region = var.region
}
