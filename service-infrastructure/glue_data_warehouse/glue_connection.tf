
resource "aws_glue_connection" "this" {
  name = "${var.prefix}-datawarehouse-db-connection"
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${var.db_instance}:5432/epb"
    SECRET_ID           = aws_secretsmanager_secret.glue_db_creds.name
  }


  physical_connection_requirements {
    availability_zone      = var.subnet_group_az
    security_group_id_list = [aws_security_group.glue_security_group.id]
    subnet_id              = var.subnet_group_id

  }

}