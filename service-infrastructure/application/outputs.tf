output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.this.arn
}


output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  value = try(aws_ecs_service.this[0].name, "")
}

output "internal_alb_dns" {
  value = local.create_internal_alb ? aws_lb.internal[0].dns_name : ""
}

output "internal_alb_arn_suffix" {
  value = local.create_internal_alb ? aws_lb.internal[0].arn_suffix : ""
}

output "internal_alb_tg_arn_suffix" {
  value = local.create_internal_alb ? aws_lb_target_group.internal[0].arn_suffix : ""
}

output "internal_alb_name" {
  value = local.create_internal_alb ? aws_lb.internal[0].name : ""
}

output "front_door_alb_arn_suffix" {
  value = var.front_door_config != null ? module.front_door[0].alb_arn_suffix : ""
}

output "front_door_alb_tg_arn_suffix" {
  value = var.front_door_config != null ? module.front_door[0].tg_arn_suffix : ""
}

output "front_door_alb_target_group_arn" {
  value = var.front_door_config != null ? module.front_door[0].lb_target_group_arn : ""
}

output "front_door_alb_extra_target_group_arns" {
  value = var.front_door_config != null ? module.front_door[0].lb_extra_target_group_arns : []
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "cloudfront_distribution_ids" {
  value = var.front_door_config != null ? module.front_door[0].cloudfront_distribution_ids : []
}

output "ecs_task_exec_arn" {
  value = try(aws_ecs_task_definition.exec_cmd_task[0].arn, "")
}

output "ecs_exec_cmd_task_family" {
  value = try(aws_ecs_task_definition.exec_cmd_task[0].family, "")
}

output "migration_container_name" {
  value = local.migration_container_name
}
output "oai_iam_arn" {
  value = var.front_door_config != null ? module.front_door[0].oai_iam_arn : ""
}

output "ecr_repository_url" {
  value = try(aws_ecr_repository.this[0].repository_url, "")
}

output "address_base_updater_container_name" {
  value = local.address_base_container_name
}

output "address_base_ecs_task_exec_arn" {
  value = try(aws_ecs_task_definition.address_base_updater_task[0].arn, "")
}