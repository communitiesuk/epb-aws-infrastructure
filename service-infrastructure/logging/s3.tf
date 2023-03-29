resource "aws_s3_bucket" "logs" {
  bucket = "${var.prefix}-logs"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket              = aws_s3_bucket.logs.id
  block_public_acls   = true
  block_public_policy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "all_logs"
    status = "Enabled"

    expiration {
      days = 14
    }
  }
}

resource "aws_s3_bucket_policy" "root_log_bucket_access" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::652711504416:root"
        }
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.logs.arn}/*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_logs_read_access" {
  name = "${var.prefix}-s3-logs-read-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Read"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.logs.arn}/*"
        ]
      },
      {
        Sid    = "List"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.logs.arn
        ]
      }
    ]
  })
}
