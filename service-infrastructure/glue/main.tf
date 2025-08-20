terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>5.98"
      source  = "hashicorp/aws"
    }
  }
}

locals {
  catalog_start_year = 2012
  catalog_end_year   = 2025
  number_years       = (local.catalog_end_year - local.catalog_start_year)
  number_of_jobs     = local.number_years + 1
}