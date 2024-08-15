resource "aws_iam_role" "ci_role" {
  name        = "ci-server"
  description = "Used by a CI server operating from a separate account"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.ci_account_id}:root"
        }
      }
    ]
  })
}



# https://docs.aws.amazon.com/AmazonECS/latest/userguide/security_iam_id-based-policy-examples.html#IAM_update_service_policies
resource "aws_iam_role_policy" "ci_ecs_policy" {
  name = "ci-ecs-policy"
  role = aws_iam_role.ci_role.id
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
          "ecs:DescribeServices",
          "iam:PassRole",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_ecr_policy" {
  role       = aws_iam_role.ci_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}


