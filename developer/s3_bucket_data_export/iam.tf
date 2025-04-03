resource "aws_iam_policy" "s3_write" {
  name        = "${var.bucket_name}-policy-s3-write"
  description = "Policy that allows write access to the bucket"

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
        Action   = "s3:*Object"
        Resource = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read" {
  name        = "${var.bucket_name}-policy-s3-read"
  description = "Policy that allows read-only access to the bucket"

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

resource "aws_iam_user" "user" {
  name = "${var.bucket_name}-team-user"
}

resource "aws_iam_access_key" "access_key" {
  user = aws_iam_user.user.name
}

resource "aws_iam_user_policy_attachment" "read" {
  policy_arn = aws_iam_policy.s3_read.arn
  user       = aws_iam_user.user.name
}

resource "aws_iam_user_policy_attachment" "write" {
  count      = var.allow_write ? 1 : 0
  policy_arn = aws_iam_policy.s3_write.arn
  user       = aws_iam_user.user.name
}
