output "error_pages_bucket_name" {
  value       = aws_s3_bucket.this.bucket_domain_name
  description = "The Access URL (using the S3 protocol for the error pages data bucket)"
}
