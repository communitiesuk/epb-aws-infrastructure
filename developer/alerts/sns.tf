resource "aws_sns_topic" "cloudwatch_to_main_slack_alerts" {
  name = "cloudwatch_to_main_slack_alerts"
}

resource "aws_sns_topic_subscription" "cloudwatch_to_main_slack_alerts_lambda" {
  topic_arn = aws_sns_topic.cloudwatch_to_main_slack_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.main_slack_alerts.arn
}

