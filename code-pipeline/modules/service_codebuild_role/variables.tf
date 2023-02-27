variable "cross_account_role_arns" {
  type = list(string)
}

variable "codepipeline_bucket_arn" {
  type = string
}


variable "codepipeline_bucket" {
  type = string
}

variable codestar_connection_arn {
  type = string
}