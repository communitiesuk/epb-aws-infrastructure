resource "aws_ecr_repository_policy" "ecr_codebuild_policy" {
  repository = aws_ecr_repository.this.name
  policy     = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
    {
      "Sid": "CodeBuildAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::145141030745:role/epbr-codebuild-role"

      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:DescribeRepositories",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages",
        "ecr:GetAuthorizationToken",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
]}
EOF
}

# https://docs.aws.amazon.com/AmazonECS/latest/userguide/security_iam_id-based-policy-examples.html#IAM_update_service_policies
resource "aws_iam_role_policy" "ecs_codebuild_policy" {
  name = "${var.prefix}-ecs-codebuild-policy"
  role = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "application-autoscaling:Describe*",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:DeleteScalingPolicy",
          "application-autoscaling:RegisterScalableTarget",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "ecs:List*",
          "ecs:Describe*",
          "ecs:UpdateService"
        ]
        Resource = "arn:aws:iam::145141030745:role/epbr-codebuild-role"
      }
    ]
  })
}