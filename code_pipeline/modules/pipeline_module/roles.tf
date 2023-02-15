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
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
    ]
    resources = [aws_codestarconnections_connection.communitiesuk_connection.arn]
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

data "aws_iam_policy_document" "codepipeline_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.codepipeline_bucket.arn,
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
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
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "codestar-connections:UseConnection",
    ]
    resources = [aws_codestarconnections_connection.communitiesuk_connection.arn]
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "${var.project_name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codebuild.json
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name   = "${var.project_name}-codebuild-policy"
  role   = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_role_policy.json
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.pipeline_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_codepipeline.json
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "${var.pipeline_name}-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_role_policy.json
}


#resource "aws_iam_role_policy" "code_deploy_policy" {
#  role   = aws_iam_role.codepipeline_role.id
#  policy = <<EOF
#  {
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Action": [
#                "ecs:DescribeServices",
#                "ecs:CreateTaskSet",
#                "ecs:UpdateServicePrimaryTaskSet",
#                "ecs:DeleteTaskSet",
#                "elasticloadbalancing:DescribeTargetGroups",
#                "elasticloadbalancing:DescribeListeners",
#                "elasticloadbalancing:ModifyListener",
#                "elasticloadbalancing:DescribeRules",
#                "elasticloadbalancing:ModifyRule",
#                "lambda:InvokeFunction",
#                "cloudwatch:DescribeAlarms",
#                "sns:Publish",
#                "s3:GetObject",
#                "s3:GetObjectVersion"
#            ],
#            "Resource": "*",
#            "Effect": "Allow"
#        },
#        {
#            "Action": [
#                "iam:PassRole"
#            ],
#            "Effect": "Allow",
#            "Resource": "*",
#            "Condition": {
#                "StringLike": {
#                    "iam:PassedToService": [
#                        "ecs-tasks.amazonaws.com"
#                    ]
#                }
#            }
#        }
#    ]
#}
#  EOF
#
#}