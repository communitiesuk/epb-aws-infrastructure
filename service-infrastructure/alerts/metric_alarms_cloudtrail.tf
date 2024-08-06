resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.unauthorized_api_calls_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.unauthorized_api_calls_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "no_mfa_console_signin_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.no_mfa_console_signin_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.no_mfa_console_signin_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "root_account_login_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.root_account_login_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.root_account_login_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.iam_policy_changes_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.iam_policy_changes_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_config_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.cloudtrail_config_changes_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.cloudtrail_config_changes_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "s3_bucket_policy_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.s3_bucket_policy_changes_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.s3_bucket_policy_changes_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "network_gateway_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.network_gateway_changes_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.network_gateway_changes_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "route_tables_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.route_tables_changes_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.route_tables_changes_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "vpc_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.vpc_changes_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.vpc_changes_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "organization_changes_alarm" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.organization_changes_metric.name}-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.organization_changes_metric.name
  namespace           = "CISBenchmark"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts_cloudtrail.arn,
  ]
}
