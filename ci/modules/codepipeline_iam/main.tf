terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>5.100"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                   = var.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
}

data "aws_caller_identity" "current" {}

locals {

  codebuild_arns = [
    for i in var.codebuild_names : "arn:aws:codebuild:${var.region}:${data.aws_caller_identity.current.account_id}:project/${i}"
  ]
}
