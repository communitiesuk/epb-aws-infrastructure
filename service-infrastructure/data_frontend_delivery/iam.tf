resource "aws_iam_policy" "sns_write_policy" {
  name        = "${var.prefix}-data-frontend-delivery-sns-write"
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