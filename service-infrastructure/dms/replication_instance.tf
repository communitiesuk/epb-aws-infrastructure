resource "aws_dms_replication_instance" "this" {
  replication_instance_class  = "dms.r4.2xlarge"
  replication_instance_id     = "${var.prefix}-${var.name}-instance"
  replication_subnet_group_id = aws_dms_replication_subnet_group.this.id
  vpc_security_group_ids      = [aws_security_group.dms.id]
  multi_az                    = true
}

resource "aws_dms_replication_subnet_group" "this" {
  replication_subnet_group_description = "subnets for the dms"
  replication_subnet_group_id          = "${var.prefix}-subnet-group"
  subnet_ids                           = var.subnet_group_ids
}


resource "aws_dms_replication_task" "this" {
  migration_type           = "full-load-and-cdc"
  replication_instance_arn = aws_dms_replication_instance.this.replication_instance_arn
  replication_task_id      = "${var.prefix}-${var.name}-task"
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  table_mappings           = jsonencode(jsondecode(file("${path.module}/warehouse_mapping.json")))
  target_endpoint_arn      = aws_dms_endpoint.target.endpoint_arn
  start_replication_task   = true

}