
resource "aws_codepipeline" "codepipeline" {
  name     = var.pipeline_name
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.codepipeline_bucket
    type     = "S3"
  }

  stage {
    name = "source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = format("%s/%s", var.github_organisation, var.github_repository)
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "run-app-tests"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_and_test_output"]

      configuration = {
        ProjectName = module.codebuild_run_app_test.codebuild_name
      }
    }
  }

  stage {
    name = "build-app-image"

    action {
      name             = "build-app-image"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["docker_image"]

      configuration = {
        ProjectName = module.codebuild_build_app_image.codebuild_name
      }
    }

    action {
      name             = "build-api-image"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["docker_api_image"]

      configuration = {
        ProjectName = module.codebuild_build_api_image.codebuild_name
      }
    }

  }

  stage {
    name = "deploy-to-pre-production"

    action {
      name            = "deploy-data-warehouse-to-integration-cluster"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_image"]
      configuration = {
        ProjectName = module.codebuild_deploy_integration.codebuild_name
      }
    }

    action {
      name            = "deploy-data-warehouse-api-to-integration-cluster"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_api_image"]
      configuration = {
        ProjectName = module.codebuild_api_deploy_integration.codebuild_name
      }
    }

    action {
      name            = "deploy-data-warehouse-api-to-staging-cluster"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_api_image"]
      configuration = {
        ProjectName = module.codebuild_api_deploy_staging.codebuild_name
      }
    }

    action {
      name            = "deploy-data-warehouse-to-staging-cluster"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_image"]
      configuration = {
        ProjectName = module.codebuild_deploy_staging.codebuild_name
      }
    }
  }

  stage {
    name = "deploy-api-to-production"

    action {
      name            = "deploy-data-warehouse-api-to-production-cluster"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_api_image"]
      configuration = {
        ProjectName = module.codebuild_api_deploy_production.codebuild_name
      }
    }
  }

  stage {
    name = "deploy-app-to-production"

    action {
      name            = "deploy-data-warehouse-to-production-cluster"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_image"]
      configuration = {
        ProjectName = module.codebuild_deploy_production.codebuild_name
      }
    }
  }
}
