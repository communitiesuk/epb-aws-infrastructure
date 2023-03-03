output "aws_s3_terraform_state" {
  value       = join("", aws_s3_bucket.epbr_s3_terraform_state[*].arn)
  description = "The bucket where the terraform state will be stored"
}

output "aws_dynamo_terraform_state" {
  value       = join("", aws_dynamodb_table.epbr_dynamo_terraform_state[*].arn)
  description = "The dynamo db where the terraform state lock will be stored"
}
