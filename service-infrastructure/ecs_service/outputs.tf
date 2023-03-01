output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "internal_alb_dns" {
  value = var.create_internal_alb ? aws_lb.internal[0].dns_name : ""
}