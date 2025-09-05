resource "aws_athena_workgroup" "this" {
  name = "${var.prefix}-user-data-workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${var.output_bucket_name}/output/"

      # encryption_configuration {
      #   encryption_option = "SSE_KMS"
      #   kms_key_arn       = aws_kms_key.example.arn
      # }
    }
  }
}