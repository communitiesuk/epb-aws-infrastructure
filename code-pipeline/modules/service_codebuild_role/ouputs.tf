output "aws_codebuild_role_arn" {
  value       = aws_iam_role.codebuild_role.arn
  description = "The arn of the code build role"
}

