output "cloudwatch_log_group_id" {
  value = aws_cloudwatch_log_group.main.id
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.main.name
}

output "cloudtrail_log_group_name" {
  value = aws_cloudwatch_log_group.cloudtrail.name
}

output "logs_bucket_name" {
  value = aws_s3_bucket.logs.bucket
}

output "logs_bucket_url" {
  value = aws_s3_bucket.logs.bucket_domain_name
}

output "cloudwatch_ecs_events_arn" {
  value = aws_cloudwatch_log_group.ecs_events.arn
}

output "cloudwatch_ecs_events_name" {
  value = aws_cloudwatch_log_group.ecs_events.name
}

