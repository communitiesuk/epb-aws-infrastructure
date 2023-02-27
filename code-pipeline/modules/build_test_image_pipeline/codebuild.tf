#### CODEBUILD ####
resource "aws_codebuild_project" "build_images" {
  for_each     = var.configurations
  name         = "epbr-codebuild-images-${each.key}-project"
  service_role = aws_iam_role.codebuild_role.arn
  tags         = var.tags

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.this[each.key].repository_url
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "${each.key}/buildspec.yml"
  }
}

#### IAM ####
data "aws_iam_policy_document" "assume_role_codebuild" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["codebuild.amazonaws.com"]
      type        = "Service"
    }
  }
}
