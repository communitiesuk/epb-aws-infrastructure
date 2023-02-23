variable "configurations" {
  description = "The configurations to create docker pipelines for"
  default = {
    "codebuild-cloudfoundry" = {
    }
    "postgres" = {
    }
  }
}

variable "tags" {
  description = "AWS asset tags"
  default = {
    Project   = "epb"
    Terraform = true
  }
}

variable "github_organisation" {
  default = "communitiesuk"
}

variable "github_repository" {
  default = "epb-docker-images"
}

variable "github_branch" {
  default = "master"
}

variable "region" {
  default = "eu-west-2"
}

variable "project_name" {
  default = "epb-codebuild-image"
}
