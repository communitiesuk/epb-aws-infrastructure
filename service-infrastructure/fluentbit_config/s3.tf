resource "aws_s3_bucket" "this" {
  bucket = "${var.prefix}-fluentbit-conf"
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "this" {
  bucket = aws_s3_bucket.this.bucket
  key    = "fluent-bit.conf"
  source = "${path.module}/config/fluent-bit.conf"
  etag   = filemd5("${path.module}/config/fluent-bit.conf")
}
