resource "aws_iam_role" "scheduler" {
  name = "start-pipeline-scheduler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["scheduler.amazonaws.com"]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler" {
  policy_arn = aws_iam_policy.scheduler.arn
  role       = aws_iam_role.scheduler.name
}

resource "aws_iam_policy" "scheduler" {
  name = "start-pipeline-scheduler-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
        Resource = [
          var.aws_ruby_node_codepipeline_arn,
          var.auth_server_codepipeline_arn,
          var.data_frontend_codepipeline_arn,
          var.fluentbit_codepipeline_arn,
          var.frontend_codepipeline_arn,
          var.reg_api_codepipeline_arn,
          var.warehouse_codepipeline_arn,
          var.postgres_codepipeline_arn
        ]
      },
    ]
  })
}
