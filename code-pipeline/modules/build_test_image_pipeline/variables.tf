variable "configurations" {
  description = "The configurations to create docker pipelines for"
  default = {
    "codebuild-cloudfoundry" = {
    }
    "postgres" = {
    }
  }
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