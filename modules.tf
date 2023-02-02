module "networking" {
  source = "./networking"
  prefix = local.prefix
  region = var.region
}