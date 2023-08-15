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

resource "aws_iam_role" "codebuild_role" {
  name               = "epbr-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codebuild.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "epbr-codebuild-policy"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : ""
      },
      {
        "Action" : [
          "ecr:UploadLayerPart",
          "ecr:PutImage",
          "ecr:ListImages",
          "ecr:InitiateLayerUpload",
          "ecr:GetRepositoryPolicy",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeRepositories",
          "ecr:CompleteLayerUpload",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : ""
      },
      {
        "Action" : [
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetObject",
          "s3:GetBucketLocation",
          "s3:GetBucketAcl"
        ],
        "Effect" : "Allow",
        "Resource" : [
          var.codepipeline_bucket_arn,
          "${var.codepipeline_bucket_arn}/*",
          var.performance_reports_bucket_arn,
          "${var.performance_reports_bucket_arn}/*",
        ],
        "Sid" : ""
      },
      {
        "Action" : [
          "s3:GetLifecycleConfiguration",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::${var.tech_docs_bucket_repo}",
        "arn:aws:s3:::${var.tech_docs_bucket_repo}/*"],
        "Sid" : ""
      },
      {
        "Action" : "codestar-connections:UseConnection",
        "Effect" : "Allow",
        "Resource" : var.codestar_connection_arn,
        "Sid" : ""
      },
      {
        "Action" : "ssm:GetParameters",
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : ""
      },
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Resource" : var.cross_account_role_arns
        "Sid" : ""
      }
    ]
  })
}
