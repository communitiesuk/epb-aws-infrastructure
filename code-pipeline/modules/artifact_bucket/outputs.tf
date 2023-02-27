output "codepipeline_bucket_arn" {
  value       = aws_s3_bucket.codepipeline_bucket.arn
  description = "The arn of the code pipeline bucket"
}

output "codepipeline_bucket_bucket" {
  value       = aws_s3_bucket.codepipeline_bucket.bucket
  description = "The bucket of the code pipeline bucket"
}