terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>5.98"
      source  = "hashicorp/aws"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

locals {
  origin_id       = "${var.prefix}-origin"
  cdn_header_name = "X-CDN-HEADER"
}
