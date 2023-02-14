output "repository_url" {
  description = "The URL of the ECR repositories "
  value       = [for ecr in aws_ecr_repository.this : ecr.repository_url]
}




