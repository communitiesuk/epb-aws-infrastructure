variable "codepipeline_bucket_arn" {
  type = string
}

variable "performance_reports_bucket_arn" {
  type = string
}

variable "codestar_connection_arn" {
  type = string
}

variable "cross_account_role_arns" {
  type = list(string)
}

variable "region" {
  type = string
}

variable "s3_buckets_to_access" {
  type = list(string)
}