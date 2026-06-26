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

locals {
  is_serverless    = var.instance_class == "db.serverless" ? true : false
  pg_major_version = split(".", var.postgres_version)[0]
}