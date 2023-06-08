resource "aws_s3_bucket" "this" {
  bucket        = "${var.prefix}-backup"
  force_destroy = false


}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
}


