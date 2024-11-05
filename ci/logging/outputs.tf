output "cloudwatch_log_group_id" {
  value = aws_cloudwatch_log_group.main.id
}

output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.main.name
}

output "cloudtrail_log_group_name" {
  value = aws_cloudwatch_log_group.cloudtrail.name
}


