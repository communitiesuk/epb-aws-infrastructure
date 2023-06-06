output "codepipeline_bucket" {
  value       = aws_s3_bucket.this.bucket
  description = "The performance test report bucket"
}

output "codepipeline_bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "The arn of the performance test report bucket"
}