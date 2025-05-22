output "image_repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "postgres_codepipeline_arn" {
  value = aws_codepipeline.postgres_image_codepipeline.arn
}
