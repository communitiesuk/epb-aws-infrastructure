variable "account_ids" {
  type = map(string)
}

variable "app_ecr_name" {
  type = string
}

variable "codebuild_image_ecr_url" {
  type = string
}

variable "codebuild_role_arn" {
  type = string
}

variable "codepipeline_arn" {
  type = string
}

variable "codepipeline_bucket" {
  type = string
}

variable "codestar_connection_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
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

variable "pipeline_name" {
  type = string
}

variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "aws_arm_codebuild_image" {
  type = string
}
