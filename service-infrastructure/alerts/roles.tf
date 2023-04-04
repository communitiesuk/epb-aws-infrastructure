
resource "aws_iam_role" "lambda_sns_subscriber" {
  name = "${var.prefix}-lambda-sns-slack"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_sns_subscriber" {
  name = "${var.prefix}-clourdwach-sns-subscriber"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = aws_sns_topic.cloudwatch_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_sns_subscriber" {
  role       = aws_iam_role.lambda_sns_subscriber.name
  policy_arn = aws_iam_policy.cloudwatch_sns_subscriber.arn
}
