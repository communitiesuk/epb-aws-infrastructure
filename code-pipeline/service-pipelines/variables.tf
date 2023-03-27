variable "account_ids" {
  type = map(string)
}

variable "cross_account_role_arns" {
  type = list(string)
}

variable "github_organisation" {
  default = "communitiesuk"
  type    = string
}

variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "smoketests_branch" {
  default = "master"
  type = string
}

variable "smoketests_repository" {
  default = "epb-frontend-smoke-tests"
  type = string
}

variable "aws_arm_codebuild_image" {
  default = "aws/codebuild/amazonlinux2-aarch64-standard:2.0"
  type    = string
}