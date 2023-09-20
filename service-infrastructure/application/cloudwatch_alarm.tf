resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  count               = var.has_responsiveness_scale == true ? 1 : 0
  alarm_description   = "scale-up-slow-response-alarm"
  alarm_name          = "${var.prefix}-up-response-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 10
  statistic           = "Maximum"
  threshold           = 2

  dimensions = {
    LoadBalancer = module.front_door[0].alb_arn_suffix
  }
  actions_enabled = true
  alarm_actions = [
    aws_appautoscaling_policy.scale_up[0].arn
  ]

}



resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  count               = var.has_responsiveness_scale == true ? 1 : 0
  alarm_description   = "scale-down-ok-response-alarm"
  alarm_name          = "${var.prefix}-down-response-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancer = module.front_door[0].alb_arn_suffix
  }
  actions_enabled = true
  alarm_actions = [
    aws_appautoscaling_policy.scale_down[0].arn
  ]

}







