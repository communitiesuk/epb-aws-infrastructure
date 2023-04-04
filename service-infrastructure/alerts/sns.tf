resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "cloudwatch_alerts"
}

resource "aws_sns_topic_subscription" "lambda_to_cloudwatch_alerts" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.send_alerts.arn
}
