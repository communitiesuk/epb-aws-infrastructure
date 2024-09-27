# Create a CloudWatch alarm for ECS CPU usage
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_usage" {
  for_each = var.ecs_services

  alarm_name          = "${each.value.service_name}-cpu-usage"
  alarm_description   = "ECS CPU utilization has been >90% for over a minute"
  namespace           = "AWS/ECS"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "CPUUtilization"
  evaluation_periods  = 1
  period              = 60
  threshold           = 90
  statistic           = "Average"

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
  alarm_description   = "ECS memory usage has been >90% for over a minute"
  namespace           = "AWS/ECS"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "MemoryUtilization"
  evaluation_periods  = 1
  period              = 60
  threshold           = 90
  statistic           = "Average"

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
  alarm_description   = "RDS Database CPU utilization has been >90% for over a minute"
  namespace           = "AWS/RDS"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "CPUUtilization"
  evaluation_periods  = 1
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
# CPUUtilization is the average of reader and writer instances, so we alert at 45% average utilization,
# which could correspond to one instance being over 90%
resource "aws_cloudwatch_metric_alarm" "rds_cluster_cpu_usage" {
  for_each = var.rds_clusters

  alarm_name          = "${each.value}-cpu-usage"
  alarm_description   = "Aurora cluster CPU utilization has been >45% for over a minute"
  namespace           = "AWS/RDS"
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "CPUUtilization"
  evaluation_periods  = 1
  period              = 60
  threshold           = 45
  statistic           = "Average"

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
  alarm_description   = "There have been >10 5xx responses at the ALB in a minute"
  namespace           = "AWS/ApplicationELB"
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  evaluation_periods  = 1
  period              = 60
  threshold           = 10
  statistic           = "Sum"

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
  alarm_description   = "There have been >5000 ALB 4xx for 3 minutes straight"
  namespace           = "AWS/ApplicationELB"
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = "HTTPCode_ELB_4XX_Count"
  evaluation_periods  = 3
  period              = 60
  threshold           = 5000
  statistic           = "Sum"

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

resource "aws_cloudwatch_metric_alarm" "ecs_task_start_failure" {
  for_each = var.ecs_services

  alarm_name          = "${each.value.service_name}-ecs-task-start-failure-alarm"
  alarm_description   = "An ECS task has failed to start and reach a healthy state"
  namespace           = "ECS"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = "ecs_task_start_failure"
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "SampleCount"
  alarm_actions       = var.main_slack_alerts == 1 ? [aws_sns_topic.cloudwatch_to_main_slack_alerts[0].arn] : [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    group = "family:${each.value.service_name}-ecs-task"
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_exec_cmd_task_failure" {
  for_each = var.exec_cmd_tasks

  alarm_name          = "${each.value}-failure-alarm"
  alarm_description   = "An ECS exec cmd task has failed"
  namespace           = "ECS"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  metric_name         = "ecs_exec_cmd_task_failure"
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "SampleCount"
  alarm_actions       = [aws_sns_topic.cloudwatch_alerts.arn]

  dimensions = {
    group = "family:${each.value}"
  }
}