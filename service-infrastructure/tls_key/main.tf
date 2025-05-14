terraform {
  required_version = "~>1.3"

  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}