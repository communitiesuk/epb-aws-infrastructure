resource "aws_cloudwatch_metric_alarm" "scale_alarm" {
  alarm_name          = "${var.prefix}-${var.alb_type}-${var.direction}-response-alarm"
  comparison_operator = var.direction == "up" ? "GreaterThanThreshold" : "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = var.direction == "up" ? 10 : 300
  statistic           = "Maximum"
  threshold           = var.direction == "up" ? 1 : 1

  dimensions = {
    LoadBalancer = var.load_balancer_suffix
  }
  actions_enabled = true
  alarm_actions = [
    var.scaling_policy
  ]
  treat_missing_data = var.direction == "up" ? "missing" : "breaching"
}