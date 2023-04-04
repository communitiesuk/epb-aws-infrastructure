output "codebuild_name" {
  value       = aws_codebuild_project.this.name
  description = "The name of the codebuild server"
}