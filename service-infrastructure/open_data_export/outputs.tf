output "open_data_export_bucket_name" {
  value       = aws_s3_bucket.open_data_export.id
  description = "The Access URL (using the S3 protocol for the Open Data Export bucket"
}

output "open_data_team_s3_access_key" {
  value       = aws_iam_access_key.open_data_team_access_key.id
  description = "The Access Key to provide to the Open Data team for S3 access"
}

output "open_data_team_s3_secret" {
  value       = aws_iam_access_key.open_data_team_access_key.secret
  description = "The Secret to provide to the Open Data team for S3 access"
}

output "open_data_s3_write_access_policy_arn" {
  value       = aws_iam_policy.s3_write.arn
  description = "A policy giving write access to the Open Data Export S3 bucket"
}
