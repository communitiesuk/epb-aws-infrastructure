terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>6.70"
      source  = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {

  codebuild_arns = [
    for i in var.codebuild_names : "arn:aws:codebuild:${var.region}:${data.aws_caller_identity.current.account_id}:project/${i}"
  ]
}
