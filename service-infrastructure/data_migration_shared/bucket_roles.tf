# https://medium.com/tensult/copy-s3-bucket-objects-across-aws-accounts-e46c15c4b9e1
resource "aws_iam_policy" "copy_backup_bucket_role" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DelegateS3Access"
        Effect = "Allow"

        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:PutObjectVersionAcl",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*",
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:PutObjectVersionAcl",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:ListMultipartUploadParts",
          "s3:CreateMultipartUpload"
        ],
        "Resource" : [
          "arn:aws:s3:::epb-register-api-db-backup",
          "arn:aws:s3:::epb-register-api-db-backup/*"
        ]
      }

    ]

  })
}

