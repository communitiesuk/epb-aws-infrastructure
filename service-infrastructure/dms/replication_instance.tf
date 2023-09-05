resource "aws_dms_replication_instance" "this" {
  replication_instance_class  = var.instance_class
  replication_instance_id     = "${var.prefix}-${var.name}-instance"
  replication_subnet_group_id = aws_dms_replication_subnet_group.this.id
  vpc_security_group_ids      = [aws_security_group.dms.id]
  multi_az                    = true
}

resource "aws_dms_replication_subnet_group" "this" {
  replication_subnet_group_description = "subnets for the dms"
  replication_subnet_group_id          = "${var.prefix}-${var.name}-subnet-group"
  subnet_ids                           = var.subnet_group_ids
}

#for info on using table mappings json
#https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Tasks.CustomizingTasks.TableMapping.SelectionTransformation.Selections.html
//NB load-order. Tables and views with higher values are loaded first.
resource "aws_dms_replication_task" "this" {
  migration_type            = "full-load-and-cdc"
  replication_instance_arn  = aws_dms_replication_instance.this.replication_instance_arn
  replication_task_id       = "${var.prefix}-${var.name}-task"
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  table_mappings            = jsonencode(jsondecode(file("${path.module}/${var.mapping_file}")))
  replication_task_settings = jsonencode(jsondecode(file("${path.module}/${var.settings_file}")))
  target_endpoint_arn       = aws_dms_endpoint.target.endpoint_arn
  start_replication_task    = true
  lifecycle {
    create_before_destroy = true
    #    ignore_changes = [
    #      replication_task_settings
    #    ]
  }
}