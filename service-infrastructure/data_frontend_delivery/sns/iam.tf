resource "aws_iam_role" "sns_role" {
  name = "${var.prefix}-sns-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sns_to_sqs_enable_cloudwatch_logs" {
  name = "${var.prefix}-sns-to-sqs-cloudwatch-logs"
  role = aws_iam_role.sns_role.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogDelivery",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:PutRetentionPolicy"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "sns_write_policy" {
  name        = "${var.prefix}-${var.name}-delivery-sns-write"
  description = "Policy that allows write access to the data_frontend sns"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.this.arn
      }
    ]
  })
}