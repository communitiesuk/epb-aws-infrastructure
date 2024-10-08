resource "aws_s3_bucket" "this" {
  bucket        = var.bucket
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket              = aws_s3_bucket.this.id
  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  index_document {
    suffix = var.key
  }
}
