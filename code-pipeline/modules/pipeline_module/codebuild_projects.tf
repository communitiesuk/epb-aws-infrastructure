

data "aws_caller_identity" "current" {}


resource "aws_codebuild_project" "build_and_test" {
  name         = "${var.project_name}-codebuild-build-and-test"
  service_role = var.codebuild_role_arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = data.aws_ecr_repository.codebuild_image.repository_url
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
    type      = "CODEPIPELINE"
    buildspec = "buildspec/build_and_test_migration.yml"
  }
}


resource "aws_codebuild_project" "build_image" {
  name         = "${var.project_name}-codebuild-build-image"
  service_role = var.codebuild_role_arn
  tags         = var.tags
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_ids["integration"]
    }

    environment_variable {
      name  = "DOCKER_IMAGE_URI"
      value = "${var.account_ids["integration"]}.dkr.ecr.${var.region}.amazonaws.com/${var.app_ecr_name}"
    }

  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/build_docker_image.yml"
  }
}



resource "aws_codebuild_project" "deploy_to_cluster" {
  name         = "${var.project_name}-codebuild-deploy"
  service_role = var.codebuild_role_arn
  tags         = var.tags
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.region
    }

    environment_variable {
      name  = "CLUSTER_NAME"
      value = var.ecs_cluster_name
    }


    environment_variable {
      name  = "SERVICE_NAME"
      value = var.ecs_service_name
    }


    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_ids["integration"]
    }


    environment_variable {
      name  = "DOCKER_IMAGE_URI"
      value = "${var.account_ids["integration"]}.dkr.ecr.${var.region}.amazonaws.com/${var.app_ecr_name}"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/deploy_to_cluster.yml"
  }
}