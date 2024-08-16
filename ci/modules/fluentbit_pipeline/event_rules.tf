resource "aws_cloudwatch_event_rule" "fluentbit_image_pipeline_event" {
  name        = "codepipeline-fluentbit-image-epbrpipelinestorage-rule"
  description = "Cloud watch event when new fluentbit image zip is uploaded to S3"

  event_pattern = <<EOF
{
  "source": ["aws.s3"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["s3.amazonaws.com"],
    "eventName": ["PutObject", "CompleteMultipartUpload", "CopyObject"],
    "requestParameters": {
      "bucketName": ["epbr-pipeline-storage"],
      "key": ["modules/fluentbit_pipeline/code.zip"]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "code-pipeline" {
  rule      = aws_cloudwatch_event_rule.fluentbit_image_pipeline_event.name
  target_id = "SendToCodePipeline"
  arn       = aws_codepipeline.fluentbit_image_codepipeline.arn
  role_arn  = aws_iam_role.pipeline_event_role.arn
}
