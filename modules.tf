module "networking" {
  source = "./networking"
  prefix = local.prefix
  region = var.region
  #  to be updated when we have the containers set up
  container_port = "55555"
}