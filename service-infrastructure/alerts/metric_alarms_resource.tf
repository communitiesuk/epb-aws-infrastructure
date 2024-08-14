# Create a CloudWatch alarm for ECS CPU usage
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_usage" {
  for_each = var.ecs_services

  alarm_name          = "${each.value.service_name}-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 90

  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  ok_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  insufficient_data_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

# Create a CloudWatch alarm for ECS memory usage
resource "aws_cloudwatch_metric_alarm" "ecs_memory_usage" {
  for_each = var.ecs_services

  alarm_name          = "${each.value.service_name}-memory-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 90

  dimensions = {
    ClusterName = each.value.cluster_name
    ServiceName = each.value.service_name
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  ok_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  insufficient_data_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}


# Create a CloudWatch alarm for RDS Instance CPU usage
resource "aws_cloudwatch_metric_alarm" "rds_cpu_usage" {
  for_each = var.rds_instances

  alarm_name          = "${each.value}-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 90

  dimensions = {
    DBInstanceIdentifier = each.value
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  ok_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  insufficient_data_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

# Create a CloudWatch alarm for RDS Cluster CPU usage
resource "aws_cloudwatch_metric_alarm" "rds_cluster_cpu_usage" {
  for_each = var.rds_clusters

  alarm_name          = "${each.value}-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 90

  dimensions = {
    DBClusterIdentifier = each.value
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  ok_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  insufficient_data_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

# Create a CloudWatch alarm for ALB 5xx errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  for_each = var.albs

  alarm_name          = "${each.value}-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = each.value
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  ok_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  insufficient_data_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

# Create a CloudWatch alarm for ALB 4xx errors
resource "aws_cloudwatch_metric_alarm" "alb_4xx_errors" {
  for_each = var.albs

  alarm_name          = "${each.value}-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1000
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = each.value
  }

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  ok_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
  insufficient_data_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "fargate_spot_instance_terminated_by_AWS" {
  alarm_name          = "${aws_cloudwatch_log_metric_filter.fargate_spot_instance_terminated_by_AWS_metric.name}-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.fargate_spot_instance_terminated_by_AWS_metric.name
  namespace           = "ECS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.cloudwatch_alerts.arn,
  ]
}

resource "aws_cloudwatch_metric_alarm" "ecs_task_failure" {
  for_each = var.ecs_services

  alarm_name          = "${each.value.service_name}-ecs-task-failure-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ecs_task_failure"
  namespace           = "ECS"
  period              = 60
  statistic           = "SampleCount"
  threshold           = 1
  alarm_description   = "task failed"
  alarm_actions       = [aws_sns_topic.cloudwatch_to_main_slack_alerts.arn]
  treat_missing_data  = "notBreaching"
  dimensions = {
    group = "family:${each.value.service_name}-ecs-task"
  }
}

