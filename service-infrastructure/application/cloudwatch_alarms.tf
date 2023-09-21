locals {
  requires_internal = var.has_responsiveness_scale && local.create_internal_alb ? 1 : 0
  requires_external = var.has_responsiveness_scale ? 1 : 0
}

module "cloudwatch_alarm_up_internal" {
  source               = "./cloudwatch_alarm"
  count                = local.requires_internal
  direction            = "up"
  load_balancer_suffix = aws_lb.internal[0].arn_suffix
  scaling_policy       = aws_appautoscaling_policy.scale_up[0].arn
  prefix               = var.prefix
  alb_type             = "internal"
}

module "cloudwatch_alarm_down_internal" {
  source               = "./cloudwatch_alarm"
  count                = local.requires_internal
  direction            = "down"
  load_balancer_suffix = aws_lb.internal[0].arn_suffix
  scaling_policy       = aws_appautoscaling_policy.scale_down[0].arn
  prefix               = var.prefix
  alb_type             = "internal"
}

module "cloudwatch_alarm_up_external" {
  source               = "./cloudwatch_alarm"
  count                = local.requires_external
  direction            = "up"
  load_balancer_suffix = module.front_door[0].alb_arn_suffix
  scaling_policy       = aws_appautoscaling_policy.scale_up[0].arn
  prefix               = var.prefix
  alb_type             = "external"
}

module "cloudwatch_alarm_down_external" {
  source               = "./cloudwatch_alarm"
  count                = local.requires_external
  direction            = "down"
  load_balancer_suffix = module.front_door[0].alb_arn_suffix
  scaling_policy       = aws_appautoscaling_policy.scale_down[0].arn
  prefix               = var.prefix
  alb_type             = "external"
}