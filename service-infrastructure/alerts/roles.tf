
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
        Resource = aws_sns_topic.cloudwatch_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_sns_subscriber" {
  role       = aws_iam_role.lambda_sns_subscriber.name
  policy_arn = aws_iam_policy.cloudwatch_sns_subscriber.arn
}


resource "aws_iam_role" "cloudtrail" {
  name = "${var.prefix}-cloudtrail"
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
  name = "${var.prefix}-cloudwatch-write-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_cloudwatch_access" {
  role       = aws_iam_role.cloudtrail.name
  policy_arn = aws_iam_policy.cloudwatch_access.arn
}

resource "aws_s3_bucket_policy" "cloudtrail_s3_access" {
  bucket = data.aws_s3_bucket.logs.id
  policy = jsonencode(
    {
      Statement = [
        {
          Action = "s3:GetBucketAcl"
          Effect = "Allow"
          Principal = {
            Service = "cloudtrail.amazonaws.com"
          }
          Resource = data.aws_s3_bucket.logs.arn
          Sid      = "AWSCloudTrailAclCheck"
        },
        {
          Action = "s3:PutObject"
          Effect = "Allow"
          Principal = {
            Service = "cloudtrail.amazonaws.com"
          }
          Resource = "${data.aws_s3_bucket.logs.arn}/cloudtrail/AWSLogs/*"
        },
        {
          Action = "s3:GetBucketAcl"
          Effect = "Allow"
          Principal = {
            Service = "cloudtrail.amazonaws.com"
          }
          Resource = "arn:aws:s3:::epb-intg-logs"
        }
      ]
      Version = "2012-10-17"
    }
  )
}
