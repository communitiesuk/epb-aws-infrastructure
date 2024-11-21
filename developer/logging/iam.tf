resource "aws_iam_role" "cloudtrail" {
  name = "developer-cloudtrail"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_access" {
  name = "developer-cloudwatch-write-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_cloudwatch_access" {
  role       = aws_iam_role.cloudtrail.name
  policy_arn = aws_iam_policy.cloudwatch_access.arn
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "trusted_events_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/events/*:*"]

    principals {
      identifiers = ["events.amazonaws.com", "delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "trusted_events_policy" {
  policy_document = data.aws_iam_policy_document.trusted_events_policy_document.json
  policy_name     = "TrustEventsToStoreLogEvents"
}
