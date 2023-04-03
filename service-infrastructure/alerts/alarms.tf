resource "aws_sns_topic" "cloudwatch_alerts" {
  name = "cloudwatch_alerts"
}

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

resource "aws_sns_topic_subscription" "lambda_to_cloudwatch_alerts" {
  topic_arn = aws_sns_topic.cloudwatch_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.send_alerts.arn
}

# create an IAM role for the lambda function to assume
resource "aws_iam_role" "lambda_sns_subscriber" {
  name = "${var.prefix}-lambda-sns-slack"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch_sns_subscriber" {
  name = "cloudwatch_alerts_sns_subscriber"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish",
        ]
        Resource = aws_sns_topic.cloudwatch_alerts.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_sns_subscriber" {
  role       = aws_iam_role.lambda_sns_subscriber.name
  policy_arn = aws_iam_policy.cloudwatch_sns_subscriber.arn
}

# Create a CloudWatch alarm for CPU utilization
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_usage" {
  for_each = var.ecs_services

  alarm_name          = "${each.value.service_name}-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 95

  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

# Create a CloudWatch alarm for memory usage
resource "aws_cloudwatch_metric_alarm" "ecs_memory_usage" {
  for_each = var.ecs_services

  alarm_name          = "${each.value.service_name}-memory-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 95

  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}
