resource "aws_s3_bucket" "logs" {
  bucket = "epb-developer-logs"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "bucket_owner" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "all_logs"
    status = "Enabled"

    filter { prefix = "" }

    expiration {
      days = 14
    }
  }
}

# Used by logit.io
resource "aws_s3_bucket_policy" "root_log_bucket_access" {
  bucket     = aws_s3_bucket.logs.id
  depends_on = [aws_s3_bucket.logs]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::652711504416:root"
        }
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.logs.arn}/*",
      },
      {
        Action = "s3:GetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Resource = [aws_s3_bucket.logs.arn]
        Sid      = "AWSCloudTrailAclCheck"
      },
      {
        Action = "s3:PutObject"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Resource = ["${aws_s3_bucket.logs.arn}/cloudtrail/AWSLogs/*"]
      }
    ]
  })
}
