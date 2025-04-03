output "bucket_name" {
  value       = aws_s3_bucket.this.id
  description = "The Access URL (using the S3 protocol)"
}

output "s3_access_key" {
  value       = aws_iam_access_key.access_key.id
  description = "The Access Key to provide to the team for S3 access"
}

output "s3_secret" {
  value       = aws_iam_access_key.access_key.secret
  description = "The Secret to provide to the team for S3 access"
}

output "s3_write_access_policy_arn" {
  value       = aws_iam_policy.s3_write.arn
  description = "A policy giving write access to the S3 bucket"
}
