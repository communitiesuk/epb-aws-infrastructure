resource "aws_s3_bucket" "this" {
  bucket        = var.prefix
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle" {
  count = var.lifecycle_prefix != null ? 1 : 0
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-in-${var.expiration_days}-days"
    status = "Enabled"

    filter {
      prefix = var.lifecycle_prefix
    }

    expiration {
      days = var.expiration_days
    }
  }
}

