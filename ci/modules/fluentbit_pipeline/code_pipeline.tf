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

resource "aws_codepipeline" "codepipeline" {
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
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "build-image"

    action {
      name             = "build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["pipeline_source"]
      output_artifacts = ["docker_image"]

      configuration = {
        ProjectName   = module.codebuild_build_image.codebuild_name
        PrimarySource = "pipeline_source"
      }
    }
  }

  stage {
    name = "push-image-integration"

    action {
      name            = "push"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_image", "pipeline_source"]

      configuration = {
        ProjectName   = module.codebuild_push_image_integration.codebuild_name
        PrimarySource = "pipeline_source"
      }
    }
  }

  stage {
    name = "push-image-staging"

    action {
      name            = "push"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_image", "pipeline_source"]

      configuration = {
        ProjectName   = module.codebuild_push_image_staging.codebuild_name
        PrimarySource = "pipeline_source"
      }
    }
  }

  stage {
    name = "push-image-production"

    action {
      name            = "push"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["docker_image", "pipeline_source"]

      configuration = {
        ProjectName   = module.codebuild_push_image_production.codebuild_name
        PrimarySource = "pipeline_source"
      }
    }
  }
}
