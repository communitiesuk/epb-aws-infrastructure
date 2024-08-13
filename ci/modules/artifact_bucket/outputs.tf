output "codepipeline_bucket" {
  value       = aws_s3_bucket.this.bucket
  description = "The bucket of the code pipeline bucket"
}

output "codepipeline_bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "The arn of the code pipeline bucket"
}
