resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backup_bucket_config" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "remove_old_files"
    status = "Enabled"
    #    filter {
    #      prefix  = "production/"
    #    }
    expiration { days = 21 }
  }


}