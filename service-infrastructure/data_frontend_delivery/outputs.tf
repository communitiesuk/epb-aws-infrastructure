output "sns_write_access_policy_arn" {
  value       = module.send_user_request_sns.sns_write_access_policy_arn
  description = "A policy that allows write access to the data_frontend sns"
}

output "sns_topic_arn" {
  value = module.send_user_request_sns.sns_topic_arn
}

output "lambda_function_names" {
  value = [module.collect_user_data_lambda.lambda_name, module.send_user_data_lambda.lambda_name]
}