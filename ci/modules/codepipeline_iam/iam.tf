locals {
  s3_allowed_action = [
    "s3:GetObject",
    "s3:GetObjectVersion",
    "s3:GetBucketVersioning",
    "s3:PutObject"
  ]


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




data "aws_iam_policy_document" "codepipeline_role_policy" {
  statement {
    effect    = "Allow"
    actions   = local.s3_allowed_action
    resources = [var.artefact_bucket_arn, "${var.artefact_bucket_arn}/*"]
  }



  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = local.codebuild_arns
  }

}

resource "aws_iam_role" "codepipeline_role" {
  name               = "epbr-codepipeline-${var.project_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codepipeline.json

}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "epbr-codepipeline-${var.project_name}-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_role_policy.json
}

resource "aws_iam_role_policy" "ecr_role_policy" {
  count = var.ecr_arns == null ? 0 : 1
  name  = "epbr-codepipeline-${var.project_name}-ecr-policy"
  role  = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
      ]
      Effect   = "Allow"
      Resource = var.ecr_arns
    }]
  })
}

resource "aws_iam_role_policy" "codestar_role_policy" {
  count = var.codestar_connection_arn == "" ? 0 : 1
  name  = "epbr-codepipeline-${var.project_name}-codestar-policy"
  role  = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "codestar-connections:UseConnection",
      ]
      Effect   = "Allow"
      Resource = var.codestar_connection_arn
    }]
  })
}



