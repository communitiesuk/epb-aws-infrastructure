# Create a CloudWatch alarm for ECS CPU usage
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
  period              = 300
  statistic           = "Average"
  threshold           = 95

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
  period              = 300
  statistic           = "Average"
  threshold           = 95

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
resource "aws_cloudwatch_metric_alarm" "rds_alb_5xx_errors" {
  for_each = var.albs

  alarm_name          = "${each.value}-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 0

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

# Create a CloudWatch alarm for ALB 5xx errors
resource "aws_cloudwatch_metric_alarm" "rds_alb_4xx_errors" {
  for_each = var.albs

  alarm_name          = "${each.value}-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 0

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
