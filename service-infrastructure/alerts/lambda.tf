
data "archive_file" "slack_alerts" {
  type        = "zip"
  source_file = "${path.module}/code/slack_alerts.py"
  output_path = "slack_alerts.zip"
}

data "archive_file" "glue_slack_alerts" {
  type        = "zip"
  source_file = "${path.module}/code/glue_slack_alerts.py"
  output_path = "glue_slack_alerts.zip"
}

# create a lambda function that sends alerts to Slack
resource "aws_lambda_function" "slack_alerts" {
  filename      = "slack_alerts.zip" # replace with the name of your lambda function code zip file
  function_name = "${var.prefix}-slack-alerts"
  role          = aws_iam_role.lambda_sns_subscriber.arn

  runtime = "python3.13"
  handler = "slack_alerts.lambda_handler"

  source_code_hash = data.archive_file.slack_alerts.output_base64sha256
  # set the environment variables for the Slack webhook URL and SNS topic ARN
  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      ENVIRONMENT       = var.environment
    }
  }
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_alerts.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_alerts.arn
}

resource "aws_lambda_function" "main_slack_alerts" {
  description   = "lambda to send pre-production alerts to the team-epb slack channel"
  count         = var.main_slack_alerts
  filename      = "slack_alerts.zip" # replace with the name of your lambda function code zip file
  function_name = "${var.prefix}-main-slack-alerts"
  role          = aws_iam_role.lambda_sns_subscriber.arn

  runtime = "python3.13"
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
  count         = var.main_slack_alerts
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main_slack_alerts[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.cloudwatch_to_main_slack_alerts[0].arn
}

resource "aws_lambda_function" "glue_slack_alerts" {
  filename      = "glue_slack_alerts.zip" # replace with the name of your lambda function code zip file
  function_name = "${var.prefix}-glue-slack-alerts"
  role          = aws_iam_role.lambda_sns_subscriber.arn

  runtime = "python3.13"
  handler = "glue_slack_alerts.lambda_handler"

  source_code_hash = data.archive_file.glue_slack_alerts.output_base64sha256
  # set the environment variables for the Slack webhook URL and SNS topic ARN
  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.glue_to_main_slack_alerts ? var.main_slack_webhook_url : var.slack_webhook_url
      ENVIRONMENT       = var.environment
    }
  }
}

resource "aws_lambda_permission" "with_sns_glue" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.glue_slack_alerts.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.eventbridge_glue_slack_alerts.arn
}
