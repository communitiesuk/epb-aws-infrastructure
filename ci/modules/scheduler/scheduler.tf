resource "aws_scheduler_schedule" "start-postgres-image-pipeline" {
  name       = "start-postgres-image-pipeline"
  group_name = "default"

  flexible_time_window {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 5
  }

  schedule_expression          = "cron(57 13 22 * ? *)"
  schedule_expression_timezone = "Europe/London"

  target {
    arn      = var.postgres_codepipeline_arn
    role_arn = aws_iam_role.scheduler.arn
  }
}