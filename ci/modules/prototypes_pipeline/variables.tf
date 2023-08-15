variable "artefact_bucket" {
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
  default = "prototypes"
}

variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "codebuild_image_ecr_url" {
  type = string
}

variable "app_image_name" {
  type = string
}

variable "aws_codebuild_image" {
  type = string
}

variable "app_ecr_name" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "developer_prefix" {
  type = string
}
