terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>5.100"
      source  = "hashicorp/aws"
    }
    random = {
      version = "~>3.1"
      source  = "hashicorp/random"
    }
  }
}


data "aws_caller_identity" "current" {}

data "aws_region" "current" {}



locals {
  rds_reboot_instance_arn = [
    "arn:aws:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${var.rds_reboot_instance.instance_id}"
  ]
}

