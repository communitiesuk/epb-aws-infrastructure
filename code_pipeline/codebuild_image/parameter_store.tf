resource "aws_ssm_parameter" "ecr_urls" {
  for_each    = aws_ecr_repository.this
  name        = "${each.key}-ecr-url"
  description = "ECR URL"
  type        = "SecureString"
  value       = each.value.repository_url

  depends_on = [
    aws_ecr_repository.this
  ]
}