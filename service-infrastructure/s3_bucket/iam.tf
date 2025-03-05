resource "aws_iam_policy" "s3_write" {
  name        = "${var.prefix}-policy-s3-write"
  description = "Policy that allows write access to an S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListObjects*"
        Resource = aws_s3_bucket.this.arn
      },
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read" {
  name        = "${var.prefix}-policy-s3-read"
  description = "Policy that allows read-only access to an S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
        ]
        Resource = [
          aws_s3_bucket.this.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}


