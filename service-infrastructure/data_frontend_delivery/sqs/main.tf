terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>5.63"
      source  = "hashicorp/aws"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.3.0"
    }

  }
}

locals {
  resource_name = "${var.prefix}-${var.name}-${var.queue_name}"
}