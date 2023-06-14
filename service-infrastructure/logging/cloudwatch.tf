resource "aws_cloudwatch_log_group" "main" {
  name = "${var.prefix}-lg"

  tags = {
    Environment = var.environment
    Application = var.prefix
  }
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name = "${var.prefix}-cloudtrail"

  tags = {
    Environment = var.environment
    Application = var.prefix
  }
}

resource "aws_iam_policy" "cloudwatch_logs_access" {
  name        = "${var.prefix}-cloudwatch-logs-access"
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
