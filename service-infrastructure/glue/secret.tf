
resource "aws_secretsmanager_secret" "glue_db_creds" {
  name = "GLUE-DATAWAREHOUSE-CREDS"
}

resource "aws_secretsmanager_secret_version" "glue_db_creds_varsion" {
  secret_id     = aws_secretsmanager_secret.glue_db_creds.id
  secret_string = <<EOF
   {
    "username": ${var.db_user}",
    "password":  ${var.db_password}"
   }
EOF
}