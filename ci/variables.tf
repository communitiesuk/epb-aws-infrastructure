variable "aws_amd_codebuild_image" {
  default = "aws/codebuild/standard:6.0"
  type    = string
}

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

variable "smoketests_branch" {
  default = "master"
  type    = string
}

variable "smoketests_repository" {
  default = "epb-frontend-smoke-tests"
  type    = string
}

variable "performance_test_repository" {
  default = "epb-performance-tests"
  type    = string
}

variable "performance_test_branch" {
  default = "main"
  type    = string
}
