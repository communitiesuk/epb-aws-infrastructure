variable "artefact_bucket" {
  type = string
}

variable "repo_bucket_name" {
  type = string
}

variable "dev_account_id" {
  type = string
}

variable "codepipeline_role_arn" {
  type = string
}

variable "codebuild_role_arn" {
  type = string
}

variable "codestar_connection_arn" {
  type = string
}
variable "github_branch" {
  type = string
}

variable "github_organisation" {
  type = string
}


variable "github_repository" {
  type = string
}

variable "project_name" {
  type    = string
  default = "tech-docs"
}

variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "configuration" {
  default = "buildspec"
  type    = string
}
