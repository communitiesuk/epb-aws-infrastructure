resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.unauthorized_api_calls_metric.name}-alarm"
  alarm_description   = "There have been >3 unauthorized calls to the AWS API in the last minute"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.unauthorized_api_calls_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 3
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "no_mfa_console_signin_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.no_mfa_console_signin_metric.name}-alarm"
  alarm_description   = "Somebody just logged in to the AWS console without MFA"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.no_mfa_console_signin_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "root_account_login_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.root_account_login_metric.name}-alarm"
  alarm_description   = "Somebody just logged in to AWS as root :fearful:"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.root_account_login_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.iam_policy_changes_metric.name}-alarm"
  alarm_description   = "IAM policies have been changed"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.iam_policy_changes_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_config_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.cloudtrail_config_changes_metric.name}-alarm"
  alarm_description   = "CloudTrail configuration has been changed"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.cloudtrail_config_changes_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "s3_bucket_policy_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.s3_bucket_policy_changes_metric.name}-alarm"
  alarm_description   = "An S3 bucket policy has been changed"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.s3_bucket_policy_changes_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "network_gateway_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.network_gateway_changes_metric.name}-alarm"
  alarm_description   = "A network gateway has been changed"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.network_gateway_changes_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "route_tables_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.route_tables_changes_metric.name}-alarm"
  alarm_description   = "A routing table has been changed"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.route_tables_changes_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "vpc_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.vpc_changes_metric.name}-alarm"
  alarm_description   = "A VPC has been changed"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.vpc_changes_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "organization_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.organization_changes_metric.name}-alarm"
  alarm_description   = "Changes have been made to the AWS organisation"
  namespace           = "CISBenchmark"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = aws_cloudwatch_log_metric_filter.organization_changes_metric.name
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}
