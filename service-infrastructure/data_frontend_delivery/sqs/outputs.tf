output "sns_write_access_policy_arn" {
  value       = aws_iam_policy.sns_write_policy.arn
  description = "A policy that allows write access to the data_frontend sns"
}

output "sns_topic_arn" {
  value = aws_sns_topic.this.arn
}