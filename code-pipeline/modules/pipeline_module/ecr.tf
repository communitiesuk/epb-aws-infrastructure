data "aws_ecr_repository" "codebuild_image" {
  name = "epbr-codebuild-cloudfoundry"
}

data "aws_ecr_repository" "postgres_image" {
  name = "epbr-postgres"
}
