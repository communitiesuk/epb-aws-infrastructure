resource "aws_cloudtrail" "source_updated" {
  name           = "codepipeline-source-trail-postgres"
  s3_bucket_name = "codepipeline-cloudtrail-placeholder-bucket-eu-west-2"
  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"

      values = ["${var.artefact_bucket_arn}/modules/postgres_image_pipeline/code.zip"]
    }
  }
}
