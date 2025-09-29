output "bucket_name" {
  value       = aws_s3_bucket.this.id
  description = "The Access URL (using the S3 protocol)"
}

output "s3_access_key" {
  value       = aws_iam_access_key.access_key.id
  description = "The Access Key to provide to the team for S3 access"
  sensitive   = true
}

output "s3_secret" {
  value       = aws_iam_access_key.access_key.secret
  description = "The Secret to provide to the team for S3 access"
  sensitive   = true
}

output "s3_readonly_access_key" {
  value       = var.allow_write ? aws_iam_access_key.readonly_access_key[0].id : null
  description = "The additional Access Key to provide to the team for read-only S3 access"
  sensitive   = true
}

output "s3_readonly_secret" {
  value       = var.allow_write ? aws_iam_access_key.readonly_access_key[0].secret : null
  description = "The additional Secret to provide to the team for read-only S3 access"
  sensitive   = true
}
