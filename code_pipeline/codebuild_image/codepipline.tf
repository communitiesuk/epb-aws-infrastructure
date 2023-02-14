resource "aws_codestarconnections_connection" "communitiesuk_connection" {
  name          = "communitiesuk-connection"
  provider_type = "GitHub"
}

#### ARTIFACT STORAGE ####
resource "aws_s3_bucket" "build_artefacts" {
  for_each      = var.configurations
  bucket        = "${var.project_name}-storage-${each.key}"
  tags          = var.tags
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  for_each            = aws_s3_bucket.build_artefacts
  bucket              = each.value.id
  block_public_acls   = true
  block_public_policy = true
}

resource "aws_codepipeline" "codepipeline" {
  for_each = var.configurations
  name     = "${var.project_name}s-${each.key}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

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
        ConnectionArn        = aws_codestarconnections_connection.communitiesuk_connection.arn
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

data "aws_iam_policy_document" "codepipeline_role_policy" {
  statement {
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = flatten([
      for bucket in aws_s3_bucket.build_artefacts :
      [
        bucket.arn,
        "${bucket.arn}/*"
      ]
    ])
  }
  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
    ]
    resources = [aws_codestarconnections_connection.communitiesuk_connection.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "assume_role_codepipeline" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["codepipeline.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.project_name}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codepipeline.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.project_name}-codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_role_policy.json
}
