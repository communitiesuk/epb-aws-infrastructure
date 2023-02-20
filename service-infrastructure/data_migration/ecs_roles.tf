resource "aws_iam_role" "ecs_task_role" {
  name = "${var.prefix}-ecsTaskRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

resource "aws_iam_policy" "s3" {
  name        = "${var.prefix}-task-policy-s3"
  description = "Policy that allows access to S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:ListObjects",
        Resource = "${aws_s3_bucket.this.arn}"
      },
      {
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = "${aws_s3_bucket.this.arn}/*"
      }

    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment_rds" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = var.rds_full_access_policy_arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.s3.arn
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

resource "aws_iam_role_policy" "password_policy_secretsmanager" {
  name = "${var.prefix}-secret-access"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:secretsmanager:eu-west-2:851965904888:secret:*"
      }
    ]
  })
}
