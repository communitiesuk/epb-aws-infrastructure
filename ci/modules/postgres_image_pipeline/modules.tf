data "aws_caller_identity" "current" {}


module "codebuild_build_push_image" {
  source             = "../codebuild_project"
  codebuild_role_arn = aws_iam_role.codebuild_role.arn
  name               = "epbr-postgres-image-project"
  build_image_uri    = "aws/codebuild/standard:7.0"
  buildspec_file     = "build_docker_image.yml"
  environment_variables = [
    { name = "REPOSITORY_URI", value = aws_ecr_repository.this.repository_url },
    { name = "AWS_ACCOUNT_ID", value = data.aws_caller_identity.current.account_id },
  ]
  region = var.region
}

