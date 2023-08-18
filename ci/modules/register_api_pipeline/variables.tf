variable "account_ids" {
  type = map(string)
}

variable "app_ecr_name" {
  type = string
}

variable "aws_codebuild_image" {
  type = string
}

variable "app_image_name" {
  type = string
}

variable "sidekiq_image_name" {
  type = string
}

variable "sidekiq_ecr_name" {
  type = string
}

variable "codebuild_image_ecr_url" {
  type = string
}

variable "codebuild_role_arn" {
  type = string
}

variable "codepipeline_role_arn" {
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

variable "ecs_sidekiq_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_sidekiq_service_name" {
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

variable "integration_prefix" {
  type = string
}

variable "performance_test_repository" {
  type = string
}

variable "performance_test_branch" {
  type = string
}


variable "pipeline_name" {
  type = string
}

variable "postgres_image_ecr_url" {
  type = string
}

variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "smoketests_repository" {
  type = string
}

variable "smoketests_branch" {
  type = string
}

variable "staging_prefix" {
  type = string
}

variable "production_prefix" {
  type = string
}

variable "static_start_page_url" {
  type = string
}

variable "front_end_domain" {
  type = string
}
