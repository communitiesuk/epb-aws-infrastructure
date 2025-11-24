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

resource "aws_iam_role" "glue_eventbridge_to_sns_role" {
  name = "${var.prefix}-eventbridge-glue-to-sns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cloudwatch_sns_subscriber" {
  name = "${var.prefix}-cloudwatch-sns-subscriber"

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
        Resource = [
          "arn:aws:sns:${var.region}:*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "eventbridge_to_sns_publish" {
  name = "${var.prefix}-eventbridge-publish-sns"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sns:Publish"]
      Resource = aws_sns_topic.eventbridge_glue_slack_alerts.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_sns_subscriber" {
  role       = aws_iam_role.lambda_sns_subscriber.name
  policy_arn = aws_iam_policy.cloudwatch_sns_subscriber.arn
}

resource "aws_iam_role_policy_attachment" "eventbridge_to_sns_publish" {
  role       = aws_iam_role.glue_eventbridge_to_sns_role.name
  policy_arn = aws_iam_policy.eventbridge_to_sns_publish.arn
}
