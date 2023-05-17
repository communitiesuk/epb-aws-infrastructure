resource "aws_s3_bucket" "this" {
  bucket        = "epbr-pipeline-storage"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket              = aws_s3_bucket.this.id
  block_public_acls   = true
  block_public_policy = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}
