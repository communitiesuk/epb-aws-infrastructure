resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}-ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.prefix}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_additional_role_policy_attachment" {
  for_each   = var.additional_task_role_policy_arns
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_additional_role_policy_attachment" {
  for_each   = var.additional_task_execution_role_policy_arns
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "secret_access" {
  for_each = var.secrets
  role     = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = each.value
      }
    ]
  })
}

resource "aws_iam_role_policy" "parameter_access" {
  for_each = var.parameters
  role     = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:GetParameters"
        ],
        Effect   = "Allow",
        Resource = each.value
      }
    ]
  })
}