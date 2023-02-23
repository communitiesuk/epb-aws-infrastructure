output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "private_alb_dns" {
  value = var.create_private_alb ? aws_lb.private[0].dns_name : ""
}