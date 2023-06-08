locals {
  s3_key_prefix = "cloudtrail"
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.prefix}-cloudtrail"
  s3_bucket_name                = data.aws_s3_bucket.logs.id
  s3_key_prefix                 = local.s3_key_prefix
  include_global_service_events = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.this.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name = "${var.prefix}-cloudtrail"
}
