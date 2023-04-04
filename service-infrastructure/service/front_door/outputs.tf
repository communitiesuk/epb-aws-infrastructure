output "lb_target_group_arn" {
  value = aws_lb_target_group.public.arn
}

output "alb_arn" {
  value = aws_lb.public.arn
}
