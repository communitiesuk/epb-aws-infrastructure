resource "aws_ecr_repository" "this" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
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
      description  = "keep last 3 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "untagged"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
    }]
  })
}









