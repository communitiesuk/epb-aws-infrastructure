resource "aws_cloudwatch_event_rule" "pipeline_run" {
  name        = "run-restart-ecs-tasks-pipeline"
  description = "Gracefully restarts all ECS tasks. This is a temporary measure to stop logs from being lost."

  schedule_expression = "cron(0 8/12 * 1/1 ? *)" # every 12 hours at 8am and 8pm
}

resource "aws_cloudwatch_event_target" "pipeline" {
  rule      = aws_cloudwatch_event_rule.pipeline_run.name
  target_id = "RestartEcsTasksPipeline"
  arn       = resource.aws_codepipeline.this.arn
  role_arn  = resource.aws_iam_role.event_role.arn
}

resource "aws_iam_role" "event_role" {
  name = "restart-ecs-tasks-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "pipeline_access" {
  name = "restart-ecs-tasks-pipeline-role-pipeline-access"
  role = aws_iam_role.event_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [
          resource.aws_codepipeline.this.arn
        ]
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
      }
    ]
  })
}
