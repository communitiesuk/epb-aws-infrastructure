
resource "aws_scheduler_schedule" "schedule" {
  name       = var.name
  group_name = var.group_name

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 5
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone

  target {
    arn      = var.pipeline_arn
    role_arn = var.iam_role_arn
  }
}
