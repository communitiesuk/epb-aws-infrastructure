terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>4.0"
      source  = "hashicorp/aws"
    }
  }
}
