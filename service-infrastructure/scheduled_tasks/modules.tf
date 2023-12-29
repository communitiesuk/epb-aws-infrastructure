module "export_not_for_publication" {
  source = "./event_rule"
  prefix = var.prefix
  rule_name = "schedule_export_not_for_publication"
  cluster_arn = var.cluster_arn
  security_group_id = var.security_group_id
  vpc_subnet_ids =var.vpc_subnet_ids
  schedule_expression = "cron(17 11 * * ? *)"
  task_arn = var.task_arn
  event_role_arn = aws_iam_role.ecs_events.arn
  command = ["bundle","exec","rake","open_data:export_not_for_publication"]
  environment = [
    {
      "name": "type_of_export",
      "value": "not_for_odc"
    },
    {
      "name": "ODE_BUCKET_NAME",
      "value": "${var.prefix}-open-data-export"
    },
  ]
  container_name = var.container_name
}