resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  count               = var.front_door_config != null ? 1 : 0
  alarm_description   = "asg-scale-up-slow-response-alarm"
  alarm_name          = "${var.prefix}-asg-up-response-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 2

  dimensions = {
    name        = "LoadBalancer"
    ServiceName = module.front_door[0].lb_target_group_arn
  }
  actions_enabled = true
  alarm_actions = [
    aws_appautoscaling_policy.scale_up.arn
  ]

}

#resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
#  alarm_description = "asg-scale-down-slow-response-alarm"
#  alarm_name          = "${var.prefix}-asg-down-response-alarm"
#  comparison_operator = "LessThanThreshold"
#  evaluation_periods  = 1
#  metric_name         = "TargetResponseTime"
#  namespace           = "AWS/ApplicationELB"
#  period              = 300
#  statistic           = "Maximum"
#  threshold           = 1
#
#  dimensions = {
#    name = "LoadBalancer"
#    ServiceName = module.front_door.lb_target_group_arn
#  }
#  actions_enabled = true
#  alarm_actions = [
#    aws_autoscaling_policy.scale_down.arn
#  ]
#
#}