resource "aws_cloudwatch_log_group" "main" {
  name              = "developer-lg"
  retention_in_days = 30

  tags = {
    Application = "developer"
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "developer-cloudtrail"
  retention_in_days = 1096

  tags = {
    Application = "developer"
  }
}

resource "aws_iam_policy" "cloudwatch_logs_access" {
  name        = "developer-cloudwatch-logs-access"
  description = "Allows read access to CloudWatch logs and describe EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Stmt1444715676000"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Sid    = "Stmt1444716576170"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}
