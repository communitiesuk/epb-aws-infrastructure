data "aws_ecr_repository" "codebuild_image" {
  name = "epbr-codebuild-cloudfoundry"
}

data "aws_ecr_repository" "postgres_image" {
  name = "epbr-postgres"
}

data "aws_caller_identity" "current" {}



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

    environment_variable {
      name  = "DOCKER_IMAGE_URI"
      value = data.aws_ecr_repository.codebuild_image.repository_url
    }

    environment_variable {
      name  = "POSTGRES_IMAGE_URL"
      value = data.aws_ecr_repository.postgres_image.repository_url
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "STAGE"
      value = "integration"
    }

  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec/build_and_test_migration.yml"
  }
}



