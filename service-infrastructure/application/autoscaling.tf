locals {
  app_autoscaling = var.task_desired_capacity > 0 ? 1 : 0
}


resource "aws_appautoscaling_target" "ecs_target" {
  count              = local.app_autoscaling
  min_capacity       = var.task_min_capacity
  max_capacity       = var.task_max_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  count              = local.app_autoscaling
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value      = 80
    scale_in_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  count              = local.app_autoscaling
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value      = 60
    scale_in_cooldown = 300
  }
}


resource "aws_appautoscaling_policy" "ecs_policy_requests" {
  count              = var.has_target_tracking == true ? 1 : 0
  name               = "requests-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = local.create_internal_alb ? "${aws_lb.internal[0].arn_suffix}/${aws_lb_target_group.internal[0].arn_suffix}" : "${module.front_door[0].alb_arn_suffix}/${module.front_door[0].tg_arn_suffix}"
    }

    target_value      = 800
    scale_in_cooldown = 300
  }
}
