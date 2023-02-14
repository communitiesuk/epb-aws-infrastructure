resource "aws_codestarconnections_connection" "communitiesuk_connection" {
  name          = "communitiesuk-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "codepipeline" {
  name     = var.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
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
        ConnectionArn         = aws_codestarconnections_connection.communitiesuk_connection.arn
        FullRepositoryId      = format("%s/%s",var.github_organisation,var.github_repository)
        BranchName            = var.github_branch
        OutputArtifactFormat  = "CODEBUILD_CLONE_REF"
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
        ProjectName = aws_codebuild_project.build_and_test.name
      }
    }
  }

}


