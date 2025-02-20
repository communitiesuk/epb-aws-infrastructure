
resource "aws_secretsmanager_secret" "glue_db_creds" {
  name = "GLUE_DATAWAREHOUSE_CREDS"
}


locals {
  secret_contents = merge(
    var.secrets,
    {
      password = var.db_user
      username = var.db_password
    }
  )
}

resource "aws_secretsmanager_secret_version" "secret_val" {
  secret_id     = aws_secretsmanager_secret.glue_db_creds.id
  secret_string = jsonencode(local.secret_contents)
}