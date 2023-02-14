variable "region" {
  default = "eu-west-2"
}

variable "codebuild_image" {
  default = "689681667086.dkr.ecr.eu-west-2.amazonaws.com/codebuild-image-codebuild-cloudfoundry:latest"
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

variable "tags" {
  description = "AWS asset tags"
  default = {
    Project   = "epb"
    Terraform = true
  }
}
