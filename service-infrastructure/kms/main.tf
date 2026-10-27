terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>6.70"
      source  = "hashicorp/aws"
    }
  }
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}
