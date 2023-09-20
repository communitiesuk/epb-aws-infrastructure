output "lb_target_group_arn" {
  value = aws_lb_target_group.public.arn
}


output "lb_extra_target_group_arns" {
  value = [for group in aws_lb_target_group.extra : group.arn]
}

output "alb_arn_suffix" {
  value = aws_lb.public.arn_suffix
}
