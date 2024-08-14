locals {
  s3_key_prefix = "cloudtrail"
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.prefix}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.logs.id
  s3_key_prefix                 = local.s3_key_prefix
  include_global_service_events = true
  is_multi_region_trail         = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn
}
