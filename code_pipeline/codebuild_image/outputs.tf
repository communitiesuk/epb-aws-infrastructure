output "repository_url" {
  description = "The URL of the ECR repositories "
  value       = join("", aws_ecr_repository.this.repository_url)
}
