resource "aws_s3_bucket" "this" {
  bucket        = "epbr-performance-test-reports"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "expire_in_30_days" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-in-30-days"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}
