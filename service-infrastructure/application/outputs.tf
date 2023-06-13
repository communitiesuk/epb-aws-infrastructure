output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "internal_alb_dns" {
  value = local.create_internal_alb ? aws_lb.internal[0].dns_name : ""
}

output "internal_alb_arn_suffix" {
  value = local.create_internal_alb ? aws_lb.internal[0].arn_suffix : ""
}

output "internal_alb_name" {
  value = local.create_internal_alb ? aws_lb.internal[0].name : ""
}

output "front_door_alb_arn_suffix" {
  value = var.front_door_config != null ? module.front_door[0].alb_arn_suffix : ""
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}
