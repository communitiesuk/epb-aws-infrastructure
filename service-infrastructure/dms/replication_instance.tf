resource "aws_dms_replication_instance" "this" {
  replication_instance_class  = "dms.t3.medium"
  replication_instance_id     = "epb-prod-warehouse-dms-instance"
  replication_subnet_group_id = aws_dms_replication_subnet_group.this.id
  vpc_security_group_ids      = [aws_security_group.dms.id]
}


resource "aws_dms_endpoint" "target" {
  endpoint_id                     = "${var.name}-target-endpoint"
  endpoint_type                   = "target"
  engine_name                     = "aurora-postgresql"
  database_name                   = var.target_db_name
  secrets_manager_arn             = var.secrets["TARGET_DB_SECRET"]
  secrets_manager_access_role_arn = aws_iam_role.dms_role.arn
}

resource "aws_dms_replication_subnet_group" "this" {
  replication_subnet_group_description = "subnets for the dms"
  replication_subnet_group_id          = "epb-prod-dms-subnet-group"
  subnet_ids                           = var.subnet_group_ids
}