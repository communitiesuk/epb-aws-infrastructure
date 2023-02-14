output "secret_arns" {
  value = { for s in aws_secretsmanager_secret.this.* : s.name => s.arn }
}