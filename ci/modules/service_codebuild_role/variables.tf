variable "codepipeline_bucket_arn" {
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