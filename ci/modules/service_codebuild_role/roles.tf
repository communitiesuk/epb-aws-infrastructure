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

data "aws_iam_policy_document" "codebuild_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]
    resources = [
      var.codepipeline_bucket_arn,
      "${var.codepipeline_bucket_arn}/*",
      var.performance_reports_bucket_arn,
      "${var.performance_reports_bucket_arn}/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
    ]
    resources = [var.codestar_connection_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = var.cross_account_role_arns
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "epbr-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codebuild.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "epbr-codebuild-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_role_policy.json
}
