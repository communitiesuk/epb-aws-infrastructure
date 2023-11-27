resource "aws_iam_policy" "policy" {
  name = "${var.bucket_name}-policy-doc"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject*",
          "s3:ListBucket",
          "s3:GetObject*",
          "s3:DeleteObject*",
          "s3:GetBucketLocation"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*",
        ]
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.policy.arn
  role       = aws_iam_role.this.name

}