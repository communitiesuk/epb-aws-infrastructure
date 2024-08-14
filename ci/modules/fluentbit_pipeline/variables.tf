variable "artefact_bucket" {
  type = string
}
variable "codepipeline_role_arn" {
  type = string
}

variable "app_ecr_name" {
  type    = string
  default = "fluentbit"
}

variable "codebuild_role_arn" {
  type = string
}

variable "project_name" {
  type = string
}

variable "pipeline_name" {
  type = string
}

variable "account_ids" {
  type = map(string)
}

variable "integration_prefix" {
  default = "epb-intg"
  type    = string
}

variable "staging_prefix" {
  default = "epb-stag"
  type    = string
}

variable "production_prefix" {
  default = "epb-prod"
  type    = string
}

variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "aws_amd_codebuild_image" {
  type = string
}

variable "fluentbit_ecr_name" {
  type = string
}
