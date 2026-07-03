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

data "aws_partition" "current" {}



locals {
  rds_reboot_instance_arns = [
    for instance in values(var.rds_reboot_aurora_instances) :
    "arn:${data.aws_partition.current.partition}:rds:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:db:${instance.instance_id}"
  ]
}
