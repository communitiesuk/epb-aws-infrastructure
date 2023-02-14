output "secret_arns" {
  value = { for k, v in var.secrets: k => aws_secretsmanager_secret.this[k].arn }
}