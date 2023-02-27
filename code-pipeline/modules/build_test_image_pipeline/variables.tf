variable "configuration" {
  type = string
}

variable "artefact_bucket" {
  type = string
}

variable "artefact_bucket_arn" {
  type = string
}

variable "region" {
  type = string
}

variable "codepipeline_arn" {
  type = string
}

variable "github_organisation" {
  type = string
}

variable "github_repository" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "project_name" {
  type = string
}

variable "tags" {
  description = "AWS asset tags"
  default = {
    Project   = "epb"
    Terraform = true
  }
}

variable "codestar_connection_arn" {
  type = string
}