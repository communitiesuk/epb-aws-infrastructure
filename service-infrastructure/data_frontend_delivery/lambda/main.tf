terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>6.70"
      source  = "hashicorp/aws"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.3.0"
    }

  }
}

