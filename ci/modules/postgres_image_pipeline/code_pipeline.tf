data "archive_file" "code_zip" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/code.zip"
}

resource "aws_s3_object" "code" {
  bucket = var.artefact_bucket
  key    = "${path.module}/code.zip"
  source = data.archive_file.code_zip.output_path

  etag = filemd5(data.archive_file.code_zip.output_path)
}

resource "aws_codepipeline" "postgres_image_codepipeline" {
  name     = var.pipeline_name
  role_arn = var.codepipeline_role_arn

  artifact_store {
    location = var.artefact_bucket
    type     = "S3"
  }
  stage {
    name = "source"

    action {
      name             = "pipeline-source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["pipeline_source"]

      configuration = {
        S3Bucket             = resource.aws_s3_object.code.bucket
        S3ObjectKey          = resource.aws_s3_object.code.key
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "build-push-image"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["pipeline_source"]

      configuration = {
        ProjectName   = module.codebuild_build_push_image.codebuild_name
        PrimarySource = "pipeline_source"
      }
    }
  }
}
