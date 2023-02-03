module "networking" {
  source = "./networking"
  prefix = local.prefix
  region = var.region
  #  to be updated when we have the containers set up
  container_port = "55555"
}

module "containers" {
  source = "./containers"
  prefix = local.prefix
  region = var.region
  #  to be updated when we have the containers set up
  container_port        = "55555"
  container_image       = "ruby" # TODO add correct image
  environment_variables = []
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  security_group_ids    = module.networking.security_group_ids
  health_check_path     = "/healthcheck"
  vpc_id                = module.networking.vpc_id
  rds_db_arn            = module.rds.rds_db_arn
}

module "rds" {
  source             = "./rds"
  prefix             = local.prefix
  vpc_id             = module.networking.vpc_id
  ecs_cluster_id     = module.containers.ecs_cluster_id
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_ids = module.networking.security_group_ids
}