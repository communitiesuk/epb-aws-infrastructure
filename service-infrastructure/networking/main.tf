terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>4.0"
      source  = "hashicorp/aws"
    }
  }
}

locals {
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["a", "b", "c"]
}