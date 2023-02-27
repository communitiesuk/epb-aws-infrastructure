
output "image_repositories" {
  value = tomap({
    for ecr in aws_ecr_repository.this : ecr.repository_url => {
      url = ecr.repository_url
    }
  })
}