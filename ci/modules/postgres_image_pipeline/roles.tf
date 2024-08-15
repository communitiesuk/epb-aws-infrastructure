data "aws_iam_policy_document" "assume_role_codebuild_image" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["codebuild.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "codebuild_image_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = ([
      var.artefact_bucket_arn,
      "${var.artefact_bucket_arn}/*"
    ])
  }


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
}

resource "aws_iam_role" "codebuild_role" {
  name               = "${var.project_name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codebuild_image.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "${var.project_name}-codebuild-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_image_role_policy.json
}

data "aws_iam_policy_document" "event_bridge_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipeline_event_role" {
  name               = "postgres-image-pipeline-event-bridge-role"
  assume_role_policy = data.aws_iam_policy_document.event_bridge_role.json
}

data "aws_iam_policy_document" "pipeline_event_role_policy" {
  statement {
    sid       = ""
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.postgres_image_codepipeline.arn]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "pipeline_event_role_policy" {
  name   = "postgres-image-codepipeline-event-role-policy"
  policy = data.aws_iam_policy_document.pipeline_event_role_policy.json
}

resource "aws_iam_role_policy_attachment" "pipeline_event_role_attach_policy" {
  role       = aws_iam_role.pipeline_event_role.name
  policy_arn = aws_iam_policy.pipeline_event_role_policy.arn
}
