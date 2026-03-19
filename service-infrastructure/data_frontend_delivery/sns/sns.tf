resource "aws_sns_topic" "this" {
  name              = "${var.prefix}-${var.name}-delivery-notifications"
  kms_master_key_id = var.kms_key_arn

  sqs_success_feedback_role_arn    = aws_iam_role.sns_role.arn
  sqs_failure_feedback_role_arn    = aws_iam_role.sns_role.arn
  sqs_success_feedback_sample_rate = var.sns_success_feedback_sample_rate
}