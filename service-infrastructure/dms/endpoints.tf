resource "aws_dms_endpoint" "target" {
  endpoint_id                     = "${var.prefix}-${var.name}-target-endpoint"
  endpoint_type                   = "target"
  engine_name                     = "aurora-postgresql"
  database_name                   = var.target_db_name
  secrets_manager_arn             = var.secrets["TARGET_DB_SECRET"]
  secrets_manager_access_role_arn = aws_iam_role.dms_role.arn
  extra_connection_attributes     = "afterConnectScript=SET session_replication_role='replica'"
}

resource "aws_dms_endpoint" "source" {
  endpoint_id                     = "${var.prefix}-${var.name}-source-endpoint"
  endpoint_type                   = "source"
  engine_name                     = "aurora-postgresql"
  database_name                   = var.source_db_name
  secrets_manager_arn             = var.secrets["SOURCE_DB_SECRET"]
  secrets_manager_access_role_arn = aws_iam_role.dms_role.arn
  ssl_mode                        = "require"

}