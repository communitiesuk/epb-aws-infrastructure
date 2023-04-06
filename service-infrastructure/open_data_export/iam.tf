resource "aws_iam_policy" "s3_write" {
  name        = "${var.prefix}-policy-s3-write"
  description = "Policy that allows write access to the Open Data Export bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListObjects*"
        Resource = aws_s3_bucket.open_data_export.arn
      },
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.open_data_export.arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read" {
  name        = "${var.prefix}-policy-s3-read"
  description = "Policy that allows read-only access to the Open Data Export bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListObjects*",
          "s3:GetObject*"
        ]
        Resource = [
          aws_s3_bucket.open_data_export.arn,
          "${aws_s3_bucket.open_data_export.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user" "open_data_team_user" {
  name = "${var.prefix}-team-user"
}

resource "aws_iam_access_key" "open_data_team_access_key" {
  user = aws_iam_user.open_data_team_user.name
}

resource "aws_iam_user_policy_attachment" "open_data_team" {
  policy_arn = aws_iam_policy.s3_read.arn
  user       = aws_iam_user.open_data_team_user.name
}
