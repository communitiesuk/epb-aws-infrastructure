
resource "aws_secretsmanager_secret" "glue_db_creds" {
  name = "GLUE_${upper(var.module_prefix)}_CREDS"
}


locals {
  secret_contents = merge(
    var.secrets,
    {
      username = var.db_user
      password = var.db_password
    }
  )
}

resource "aws_secretsmanager_secret_version" "secret_val" {
  secret_id     = aws_secretsmanager_secret.glue_db_creds.id
  secret_string = jsonencode(local.secret_contents)
}