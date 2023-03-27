
resource "aws_codepipeline" "codepipeline" {
  name     = var.pipeline_name
  role_arn = var.codepipeline_arn

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

    action {
      name     = "SmokeTestsSource"
      category = "Source"
      owner    = "AWS"
      provider = "CodeStarSourceConnection"
      version  = "1"
      output_artifacts = ["smoke_tests_source_output"]

      configuration = {
        ConnectionArn = var.codestar_connection_arn
        FullRepositoryId     = format("%s/%s", var.github_organisation, var.smoketests_repository)
        BranchName = var.smoketests_branch
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
    name = "build-docker-image"

    action {
      name             = "Build"
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
  }

  stage {
    name = "deploy-to-integration"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_image"]
      configuration = {
        ProjectName = module.codebuild_deploy_integration.codebuild_name
      }
    }
  }

  stage {
    name = "frontend-smoke-test"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["smoke_tests_source_output"]
      output_artifacts = ["frontend_smoke_test_output"]

      configuration = {
        ProjectName = module.codebuild_frontend_smoke_test.codebuild_name
      }
    }
  }
}
