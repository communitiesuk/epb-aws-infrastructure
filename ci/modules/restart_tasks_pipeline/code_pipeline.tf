resource "aws_s3_object" "code" {
  bucket = var.codepipeline_bucket
  key    = "restart-tasks-pipeline/run.sh"
  source = "${path.module}/code/run.sh"
}

resource "aws_codepipeline" "this" {
  name     = var.pipeline_name
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.codepipeline_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        S3Bucket             = resource.aws_s3_object.code.bucket
        S3ObjectKey          = resource.aws_s3_object.code.key
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]

      configuration = {
        ProjectName = module.codebuild_restart_integration.codebuild_name
      }
    }
  }
}
