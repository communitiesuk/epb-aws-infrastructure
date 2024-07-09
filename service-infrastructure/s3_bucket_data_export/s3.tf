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

moved {
  from = aws_s3_bucket.open_data_export
  to   = aws_s3_bucket.this
}