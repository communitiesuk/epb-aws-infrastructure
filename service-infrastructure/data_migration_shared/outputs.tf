output "ecr_repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "backup_bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "backup_bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "log_group" {
  value = aws_cloudwatch_log_group.this.id
}