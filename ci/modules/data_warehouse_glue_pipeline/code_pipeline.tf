
resource "aws_codepipeline" "codepipeline" {
  name     = var.pipeline_name
  role_arn = module.codepipeline_iam.aws_codepipeline_role_arn

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
        ConnectionArn    = var.codestar_connection_arn
        FullRepositoryId = format("%s/%s", var.github_organisation, var.github_repository)
        BranchName       = var.github_branch
      }
    }
  }

  stage {
    name = "run-tests"

    action {
      name            = "Test"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = module.codebuild_run_test.codebuild_name
      }
    }
  }

  stage {
    name = "deploy-to-pre-production"

    action {
      name            = "deploy-data-warehouse-glue-jobs-to-integration"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]
      configuration = {
        ProjectName = module.codebuild_deploy_integration.codebuild_name
      }
    }

    # action {
    #   name            = "deploy-data-warehouse-glue-jobs-to-staging"
    #   category        = "Build"
    #   owner           = "AWS"
    #   provider        = "CodeBuild"
    #   version         = "1"
    #   input_artifacts = ["source_output"]
    #   configuration = {
    #     ProjectName = module.codebuild_deploy_staging.codebuild_name
    #   }
    # }
  }

  # stage {
  #   name = "deploy-to-production"
  #
  #   action {
  #     name            = "deploy-data-warehouse-glue-jobs-to-production"
  #     category        = "Build"
  #     owner           = "AWS"
  #     provider        = "CodeBuild"
  #     version         = "1"
  #     input_artifacts = ["source_output"]
  #     configuration = {
  #       ProjectName = module.codebuild_deploy_production.codebuild_name
  #     }
  #   }
  # }
}
