resource "aws_iam_role_policy" "ci_ecs_policy" {
  name = "ci-ecs-policy"
  role = var.ci_role_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ec2:Describe*",
          "ecs:RunTask",
          "ecs:DescribeTasks",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}
