resource "aws_s3_bucket" "epbr_s3_terraform_state" {
  bucket        = "epbr-${var.environment}-terraform-state"
  force_destroy = false
  acl           = "private"
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.epbr_s3_terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket                  = aws_s3_bucket.epbr_s3_terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
