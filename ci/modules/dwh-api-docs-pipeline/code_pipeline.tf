resource "aws_codepipeline" "codepipeline" {
  name     = "epb-${var.project_name}-pipeline"
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.artefact_bucket
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
      output_artifacts = ["code_source"]

      configuration = {
        ConnectionArn        = var.codestar_connection_arn
        FullRepositoryId     = "${var.github_organisation}/${var.github_repository}"
        BranchName           = var.github_branch
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
      }
    }
  }

  stage {
    name = "build-and-push-to-s3"

    action {
      name             = "Build-integration"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["code_source"]
      output_artifacts = ["build_and_push_to_output_intg"]
      configuration = {
        ProjectName = module.codebuild_build_push_repo_intg.codebuild_name
      }
    }

    action {
      name             = "Build-staging"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["code_source"]
      output_artifacts = ["build_and_push_to_output_stag"]
      configuration = {
        ProjectName = module.codebuild_build_push_repo_stag.codebuild_name
      }
    }

    action {
      name             = "Build-production"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["code_source"]
      output_artifacts = ["build_and_push_to_output_prod"]
      configuration = {
        ProjectName = module.codebuild_build_push_repo_prod.codebuild_name
      }
    }
  }
}
