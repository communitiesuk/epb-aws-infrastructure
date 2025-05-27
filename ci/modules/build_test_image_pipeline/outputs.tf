output "image_repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "aws_ruby_node_codepipeline_arn" {
  value = aws_codepipeline.codepipeline.arn
}
