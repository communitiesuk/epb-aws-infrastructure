
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
    name = "build-and-test"

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
}
