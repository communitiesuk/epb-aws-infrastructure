output "dynamodb_write_policy_arn" {
  value       = aws_iam_policy.dynamodb_write_access.arn
  description = "A policy giving write access to the DynamoDB table via VPC endpoint"
}

output "dynamodb_read_policy_arn" {
  value       = aws_iam_policy.dynamodb_read_access.arn
  description = "A policy giving read access to the DynamoDB table via VPC endpoint"
}

output "table_name" {
  value       = aws_dynamodb_table.this.name
  description = "The name of the legacy DynamoDB credentials table"
}

output "table_v2_name" {
  value       = aws_dynamodb_table.v2.name
  description = "The name of the new DynamoDB credentials table"
}

