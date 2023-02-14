output "aws_ecr_repo" {
  value       = aws_ecr_repository.this.arn
  description = "The ecr repo for the backup image"
}

output "aws_s3_migration_bucket" {
  value       = aws_s3_bucket.this.arn
  description = "The bucket where the backups are be stored"
}