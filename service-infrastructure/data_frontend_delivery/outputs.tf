output "sns_write_access_policy_arn" {
  value       = module.collect_data_queue.sns_write_access_policy_arn
  description = "A policy that allows write access to the data_frontend sns"
}

output "sns_topic_arn" {
  value = module.collect_data_queue.sns_topic_arn
}