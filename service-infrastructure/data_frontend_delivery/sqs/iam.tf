resource "aws_iam_policy" "sns_write_policy" {
  name        = "${local.resource_name}-sns-write"
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

resource "aws_iam_role_policy" "sqs_consumer_access" {
  name = "${var.prefix}-sqs-consumer-access"
  role = var.lambda_role_id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes",
          ]
          Effect = "Allow"
          Resource = [
            aws_sqs_queue.this.arn
          ]
        }
      ]
    })
}