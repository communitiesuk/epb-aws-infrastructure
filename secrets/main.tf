resource "aws_secretsmanager_secret" "this" {
  count = length(var.secrets)
  name  = keys(var.secrets)[count.index]
}

resource "aws_secretsmanager_secret_version" "this" {
  count         = length(aws_secretsmanager_secret.this.*)
  secret_id     = aws_secretsmanager_secret.this[count.index].id
  secret_string = var.secrets[aws_secretsmanager_secret.this[count.index].name]
}