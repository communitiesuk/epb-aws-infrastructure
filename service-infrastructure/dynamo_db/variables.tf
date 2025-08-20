variable "prefix" {
  type = string
}

variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "environment" {
  type = string
}

variable "dynamodb_service_name" {
  default = "dynamodb"
  type    = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for DynamoDB encryption"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "ecs_roles" {
  type        = list(string)
  description = "List of IAM role ARNs that will be granted access to the DynamoDB table"
}

variable "route_table_ids" {
  type        = list(string)
  description = "List of route table IDs for the VPC endpoint"
}