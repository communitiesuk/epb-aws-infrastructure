
data "archive_file" "slack_alerts" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "slack_alerts.zip"
}

resource "aws_lambda_function" "main_slack_alerts" {
  description   = "lambda to send pre-production alerts to the team-epb slack channel"
  filename      = "slack_alerts.zip" # replace with the name of your lambda function code zip file
  function_name = "developer-main-slack-alerts"
  role          = aws_iam_role.lambda_sns_subscriber.arn

  runtime = "python3.9"
  handler = "slack_alerts.lambda_handler"

  source_code_hash = data.archive_file.slack_alerts.output_base64sha256
  # set the environment variables for the Slack webhook URL and SNS topic ARN
  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.main_slack_webhook_url
      ENVIRONMENT       = var.environment
    }
  }
}

resource "aws_lambda_permission" "main_slack_alerts_with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main_slack_alerts.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_to_main_slack_alerts.arn
}
