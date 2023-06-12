resource "aws_s3_bucket" "open_data_export" {
  bucket        = var.prefix
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.open_data_export.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
