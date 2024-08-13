#https://mismo.team/deploying-event-driven-ecs-tasks-using-aws-evenbridge-and-fargate/

resource "aws_cloudwatch_event_rule" "this" {
  name                = "${var.prefix}-${var.rule_name}"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "target" {
  arn      = var.task_config.cluster_arn
  rule     = aws_cloudwatch_event_rule.this.name
  role_arn = var.task_config.event_role_arn

  ecs_target {
    task_count          = 1
    task_definition_arn = var.task_config.task_arn
    network_configuration {
      subnets         = var.task_config.vpc_subnet_ids
      security_groups = [var.task_config.security_group_id]
    }
    launch_type            = "FARGATE"
    enable_execute_command = true
  }

  input = jsonencode({
    containerOverrides = [
      {
        name        = var.task_config.container_name
        command     = var.command,
        environment = var.environment
      }
    ]
  })

}
