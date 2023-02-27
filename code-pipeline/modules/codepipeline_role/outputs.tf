output "aws_codepipeline_arn" {
  value       = aws_iam_role.codepipeline_role.arn
  description = "The arn of the code pipeline"
}

