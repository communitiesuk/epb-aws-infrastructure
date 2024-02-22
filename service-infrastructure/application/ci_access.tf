resource "aws_ecr_repository_policy" "ecr_codebuild_policy" {
  count      = local.has_ecr
  repository = aws_ecr_repository.this[0].name
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "CodeBuildAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.ci_account_id}:role/epbr-codebuild-role"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:GetAuthorizationToken",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
      }
    ]
  })
}
