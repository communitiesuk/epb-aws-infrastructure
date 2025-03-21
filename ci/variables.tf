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

variable "developer_prefix" {
  default = "epb-dev"
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

variable "tech_docs_bucket_repo" {
  type = string
}

variable "api_docs_bucket" {
  type = string
}

variable "static_start_page_url" {
  type    = string
  default = "http://epb-static-start-pages-integration.s3-website.eu-west-2.amazonaws.com"
}

variable "front_end_domain" {
  type    = string
  default = "digital.communities.gov.uk"
}

variable "parameters" {
  description = "A map of parameter values. Keys should be a subset of the ones passed to 'parameters' module."
  type        = map(string)
  sensitive   = true
}