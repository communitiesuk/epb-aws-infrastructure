output "ons_postcode_bucket_name" {
  value       = aws_s3_bucket.this.id
  description = "The Access URL (using the S3 protocol for the ONS postcode data bucket"
}

output "ons_postcode_s3_write_access_policy_arn" {
  value       = aws_iam_policy.s3_write.arn
  description = "A policy giving write access to the ONS postcode data S3 bucket"
}


output "ons_postcode_s3_read_access_policy_arn" {
  value       = aws_iam_policy.s3_read.arn
  description = "A policy giving write access to the ONS postcode data S3 bucket"
}

