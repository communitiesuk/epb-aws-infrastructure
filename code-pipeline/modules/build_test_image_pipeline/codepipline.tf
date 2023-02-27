

#### ARTIFACT STORAGE ####
resource "aws_s3_bucket" "build_artefacts" {
  for_each      = var.configurations
  bucket        = "${var.project_name}-storage-${each.key}"
  tags          = var.tags
  force_destroy = true
}

resource "aws_codepipeline" "codepipeline" {
  for_each = var.configurations
  name     = "epbr-${each.key}-image-pipeline"
  role_arn = var.codepipeline_arn

  artifact_store {
    location = aws_s3_bucket.build_artefacts[each.key].bucket
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
    name = "build-image"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build_images[each.key].name
      }
    }
  }
}

