terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>5.63"
      source  = "hashicorp/aws"
    }
  }
}
