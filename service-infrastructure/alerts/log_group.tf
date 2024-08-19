resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.prefix}-main-slack-alerts"
  count             = var.main_slack_alerts
  retention_in_days = 1
}