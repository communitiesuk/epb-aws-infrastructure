variable "prefix" {
  type = string
}

variable "region" {
  default = "eu-west-2"
  type = string
}

variable "environment" {
  type = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for DynamoDB encryption"
  type        = string
}