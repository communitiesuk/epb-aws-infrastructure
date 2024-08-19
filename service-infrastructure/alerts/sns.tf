resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "cloudwatch_alerts"
}

resource "aws_sns_topic_subscription" "lambda_to_cloudwatch_alerts" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alerts.arn
}

resource "aws_sns_topic" "cloudwatch_to_main_slack_alerts" {
  count = var.main_slack_alerts
  name  = "cloudwatch_to_main_slack_alerts"
}

resource "aws_sns_topic_subscription" "cloudwatch_to_main_slack_alerts_lambda" {
  count     = var.main_slack_alerts
  topic_arn = aws_sns_topic.cloudwatch_to_main_slack_alerts[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.main_slack_alerts[0].arn
}

