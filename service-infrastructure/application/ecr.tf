resource "aws_ecr_repository" "this" {
  count                = local.has_ecr
  name                 = "${var.prefix}-ecr"
  image_tag_mutability = "MUTABLE"
}


resource "aws_ecr_lifecycle_policy" "main" {
  count      = local.has_ecr
  repository = aws_ecr_repository.this[0].name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep 1 latest image"
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
      },
      {
        rulePriority = 2
        description  = "keep last 10 images"
        action = {
          type = "expire"
        }
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
      },
    ]
  })
}









