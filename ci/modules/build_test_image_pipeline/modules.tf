data "aws_caller_identity" "current" {}

module "codepipeline_iam" {
  source                  = "../codepipeline_iam"
  project_name            = "ruby-node-image"
  region                  = var.region
  codestar_connection_arn = var.codestar_connection_arn
  codebuild_names         = ["epbr-codebuild-images-${var.configuration}-project"]
  ecr_arns                = ["arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${aws_ecr_repository.this.name}/"]
  artefact_bucket_arn     = var.artefact_bucket_arn
}

module "codebuild_build_push_image" {
  source             = "../codebuild_project"
  codebuild_role_arn = aws_iam_role.codebuild_role.arn
  name               = "epbr-codebuild-images-${var.configuration}-project"
  build_image_uri    = "aws/codebuild/standard:7.0"
  buildspec_file     = var.build_spec_file
  environment_variables = [
    { name = "REPOSITORY_URI", value = aws_ecr_repository.this.repository_url },
    { name = "AWS_ACCOUNT_ID", value = data.aws_caller_identity.current.account_id },
  ]
  region = var.region
}
