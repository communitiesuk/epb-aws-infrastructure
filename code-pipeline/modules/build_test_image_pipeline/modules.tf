module "codebuild_build_push_image" {
  source             = "../codebuild_project"
  codebuild_role_arn = aws_iam_role.codebuild_role.arn
  name               = "epbr-codebuild-images-${var.configuration}-project"
  build_image_uri    = "aws/codebuild/standard:2.0"
  environment_type   = "LINUX_CONTAINER"
  buildspec_file     = "${var.configuration}/buildspec.yml"
  environment_variables = [
    { name = "REPOSITORY_URI", value = aws_ecr_repository.this.repository_url },
  ]
  region = var.region
}