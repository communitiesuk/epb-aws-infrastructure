resource "aws_ecr_repository" "this" {
  name                 = "epbr-postgres"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

resource "aws_ecr_repository_policy" "policy" {
  repository = aws_ecr_repository.this.name
  policy     = data.aws_iam_policy_document.ecr_policy.json
}

data "aws_iam_policy_document" "ecr_policy" {
  statement {
    sid    = "ECRAccessPolicy"
    effect = "Allow"

    principals {
      identifiers = ["codebuild.amazonaws.com"]
      type        = "Service"
    }

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
    ]
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep 1 latest tagged image"
      action = {
        type = "expire"
      }
      selection = {
        "tagPrefixList" : [
          "latest"
        ],
        tagStatus   = "tagged"
        countType   = "imageCountMoreThan"
        countNumber = 1
      }
      }, {
      rulePriority = 2
      description  = "keep last 5 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
    }]
  })
}
