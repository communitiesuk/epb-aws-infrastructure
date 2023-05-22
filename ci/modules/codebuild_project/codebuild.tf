resource "aws_codebuild_project" "this" {
  name         = var.name
  service_role = var.codebuild_role_arn


  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = var.build_image_uri
    type            = var.codebuild_environment_type
    privileged_mode = true

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.value["name"]
        value = environment_variable.value["value"]
      }
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_file

  }
}
