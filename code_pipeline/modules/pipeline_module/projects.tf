resource "aws_codebuild_project" "build_and_test" {
  name         = "${var.project_name}-codebuild-build-and-test"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "ruby:3.0"
    type         = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type      = "CODEPIPELINE"
  }
}