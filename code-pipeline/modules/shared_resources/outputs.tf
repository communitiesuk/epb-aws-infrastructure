output "codepipeline_bucket_arn" {
  value       = aws_s3_bucket.codepipeline_bucket.arn
  description = "The arn of the code pipeline bucket"
}

output "codepipeline_bucket_bucket" {
  value       = aws_s3_bucket.codepipeline_bucket.bucket
  description = "The bucket of the code pipeline bucket"
}

output "communitiesuk_connection_arn" {
  value       = aws_codestarconnections_connection.communitiesuk_connection.arn
  description = "The arn of the code star connection"
}

output "codebuild_role_arn" {
  value       = aws_iam_role.codebuild_role.arn
  description = "The arn of the code build role"
}
