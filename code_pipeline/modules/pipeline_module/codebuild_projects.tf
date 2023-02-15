data "aws_ecr_repository" "codebuild_image" {
  name = "epbr-codebuild-cloudfoundry"
}


resource "aws_codebuild_project" "build_and_test" {
  name         = "${var.project_name}-codebuild-build-and-test"
  service_role = aws_iam_role.codebuild_role.arn


  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           =  data.aws_ecr_repository.codebuild_image.repository_url
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type = "CODEPIPELINE"
  }
}



