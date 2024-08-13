output "codestar_connection_arn" {
  value       = aws_codestarconnections_connection.codestar_connection.arn
  description = "The arn of the code star connection"
}
