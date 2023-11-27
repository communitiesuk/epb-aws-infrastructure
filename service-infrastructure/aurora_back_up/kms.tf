resource "aws_kms_key" "this" {
  description             = "KMS key for aurora s3 backup"
  deletion_window_in_days = 10

}


resource "aws_iam_policy" "kms_policy" {
  name = "${var.bucket_name}-kms-policy-doc"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey",
          "kms:RetireGrant"
        ]
        Effect   = "Allow"
        Resource = [aws_kms_key.this.arn]
      },
    ]
  })
}




resource "aws_iam_role_policy_attachment" "kms_policy_attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.kms_policy.arn
}