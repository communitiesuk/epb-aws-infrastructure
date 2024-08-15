resource "aws_cloudwatch_event_rule" "postgres_image_pipeline_event" {
  name        = "codepipeline-postgres-image-epbrpipelinestorage-rule"
  description = "Cloud watch event when zip is uploaded to s3"

  event_pattern = <<EOF
{
  "source": ["aws.s3"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["s3.amazonaws.com"],
    "eventName": ["PutObject", "CompleteMultipartUpload", "CopyObject"],
    "requestParameters": {
      "bucketName": ["epbr-pipeline-storage"],
      "key": ["modules/postgres_image_pipeline/code.zip"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "code-pipeline" {
  rule      = aws_cloudwatch_event_rule.postgres_image_pipeline_event.name
  target_id = "SendToCodePipeline"
  arn       = aws_codepipeline.postgres_image_codepipeline.arn
  role_arn  = aws_iam_role.pipeline_event_role.arn
}
