resource "aws_cloudwatch_event_rule" "glue_failure" {
  name = "${var.prefix}-glue-failure-rule"

  event_pattern = jsonencode({
    source        = ["aws.glue"],
    "detail-type" = ["Glue Job State Change"],
    detail = {
      state = ["FAILED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "glue_failure_to_slack" {
  rule     = aws_cloudwatch_event_rule.glue_failure.name
  arn      = aws_sns_topic.eventbridge_glue_slack_alerts.arn
  role_arn = aws_iam_role.glue_eventbridge_to_sns_role.arn
}