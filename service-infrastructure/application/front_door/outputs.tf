output "lb_target_group_arn" {
  value = aws_lb_target_group.public.arn
}


output "lb_extra_target_group_arns" {
  value = [for group in aws_lb_target_group.extra : group.arn]
}

output "alb_arn_suffix" {
  value = aws_lb.public.arn_suffix
}

output "tg_arn_suffix" {
  value = aws_lb_target_group.public.arn_suffix
}

output "cloudfront_distribution_ids" {
  value = [for cdn in aws_cloudfront_distribution.cdn : { id = cdn.id, name = flatten(cdn.aliases)[0] }]
}

output "oai_iam_arn" {
  value = var.cdn_include_static_error_pages ? aws_cloudfront_origin_access_identity.error_pages[0].iam_arn : ""
}
