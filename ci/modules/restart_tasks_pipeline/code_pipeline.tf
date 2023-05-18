data "archive_file" "code_zip" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/code.zip"
}

resource "aws_s3_object" "code" {
  bucket = var.codepipeline_bucket
  key    = "${path.module}/code.zip"
  source = data.archive_file.code_zip.output_path

  etag = filemd5(data.archive_file.code_zip.output_path)
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
