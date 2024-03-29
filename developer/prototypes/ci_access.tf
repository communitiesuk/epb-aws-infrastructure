resource "aws_ecr_repository_policy" "ecr_codebuild_policy" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid    = "CodeBuildAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::145141030745:role/epbr-codebuild-role"
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
