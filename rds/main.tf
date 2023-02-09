resource "random_password" "password" {
  length  = 16
  special = false
}

locals {
  engine_version = var.engine == "postgres" ? "14.6" : "13.7"
}