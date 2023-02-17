variable "region" {
  default = "eu-west-2"
}



variable "github_organisation" {
  default = "communitiesuk"
}

variable "github_repository" {
  type = string
}

variable "github_branch" {
  type = string
}

variable "pipeline_name" {
  type = string
}

variable "project_name" {
  type = string
}
variable "app_ecr_name" {
  type = string
}



variable "tags" {
  description = "AWS asset tags"
  default = {
    Project   = "epb"
    Terraform = true
  }
}


variable "codepipeline_bucket_arn" {
  type = string
}


variable "codepipeline_bucket" {
  type = string
}

variable "communitiesuk_connection_arn" {
  type = string
}

variable "codebuild_role_arn" {
  type = string
}

variable "account_ids" {
  type = map(string)
}
