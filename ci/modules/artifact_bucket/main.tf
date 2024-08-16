terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>5.63"
      source  = "hashicorp/aws"
    }
  }
}


provider "aws" {
  region                   = var.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
}

