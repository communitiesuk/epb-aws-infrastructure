
data "archive_file" "send_alerts" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "slack_alerts.zip"
}

# create a lambda function that sends alerts to Slack
resource "aws_lambda_function" "send_alerts" {
  filename      = "slack_alerts.zip" # replace with the name of your lambda function code zip file
  function_name = "slack_alerts"
  role          = aws_iam_role.lambda_sns_subscriber.arn

  runtime = "python3.9"
  handler = "slack_alerts.lambda_handler"

  source_code_hash = data.archive_file.send_alerts.output_base64sha256
  # set the environment variables for the Slack webhook URL and SNS topic ARN
  environment {
    variables = {
      SLACK_WEBHOOK_URL = data.aws_ssm_parameter.alert_slack_webhook_url.value
    }
  }
}