resource "aws_s3_bucket" "epbr_s3_terraform_state" {
  bucket        = "epbr-terraform-state"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket              = aws_s3_bucket.epbr_s3_terraform_state.id
  block_public_acls   = true
  block_public_policy = true
}
