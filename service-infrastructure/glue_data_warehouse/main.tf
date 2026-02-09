terraform {
  required_version = "~>1.3"

  required_providers {
    aws = {
      version = "~>5.100"
      source  = "hashicorp/aws"
    }
  }
}

locals {
  catalog_start_year = 2012
  catalog_end_year   = 2026 #Change to the current year if the catalog needs to be repopulated
  number_years       = (local.catalog_end_year - local.catalog_start_year)
  number_of_jobs     = local.number_years + 1
}