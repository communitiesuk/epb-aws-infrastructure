terraform {
  required_version = "~>1.3"
  required_providers {
    aws = {
      version = "~>5.63"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {}
}

provider "aws" {
  alias                    = "us-east"
  region                   = "us-east-1"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}

provider "aws" {
  region                   = "eu-west-2"
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}

locals {
  prefix     = "epb-${var.environment}"
  redis_port = 6379
}
