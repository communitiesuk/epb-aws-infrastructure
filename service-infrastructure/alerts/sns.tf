resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "cloudwatch_alerts"
}

resource "aws_sns_topic" "cloudwatch_alerts_cloudtrail" {
  name = "cloudwatch_alerts_cloudtrail"
}

resource "aws_sns_topic_subscription" "lambda_to_cloudwatch_alerts" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_alerts.arn
}
