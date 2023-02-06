resource "aws_secretsmanager_secret" "this" {
  for_each      = var.secrets
  name          = "${var.prefix}-${each.key}"
  secret_string = each.value
}