data "aws_s3_bucket" "logs" {
  bucket = var.logs_bucket_name
}
