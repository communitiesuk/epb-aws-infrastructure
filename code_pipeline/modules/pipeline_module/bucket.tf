resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "${var.pipeline_name}-storage"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket              = aws_s3_bucket.codepipeline_bucket.id
  block_public_acls   = true
  block_public_policy = true
}
