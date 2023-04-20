# https://medium.com/tensult/copy-s3-bucket-objects-across-aws-accounts-e46c15c4b9e1
resource "aws_s3_bucket_policy" "backup_bucket_role" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid =  "DelegateS3Access"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::689681667086:root"
        }
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*",
        ]
      }
    ]
  })
}