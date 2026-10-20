output "config_arn" {
  value = aws_s3_object.this.arn
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}

output "fluentbit_ecr_url" {
  value = var.fluentbit_ecr_url
}
