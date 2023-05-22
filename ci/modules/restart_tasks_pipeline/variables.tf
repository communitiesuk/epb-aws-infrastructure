variable "account_ids" {
  type = map(string)
}

variable "codebuild_role_arn" {
  type = string
}

variable "codepipeline_role_arn" {
  type = string
}

variable "aws_codebuild_image" {
  type = string
}

variable "codepipeline_bucket" {
  type = string
}

variable "pipeline_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "integration_prefix" {
  type = string
}

variable "staging_prefix" {
  type = string
}

#variable "production_prefix" {
#  type = string
#}
