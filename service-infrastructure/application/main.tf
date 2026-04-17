terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>5.100"
      source  = "hashicorp/aws"
    }
  }
}

locals {
  has_ecr = var.external_ecr == "" ? 1 : 0

  parameters = {
    for k, v in var.parameters :
    k => v
    if !contains(var.parameter_filter, k)
  }
}


