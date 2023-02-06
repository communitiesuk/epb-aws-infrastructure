module "networking" {
  source = "./networking"
  prefix = local.prefix
  region = var.region
  #  to be updated when we have the containers set up
  container_port = "55555"
}

module "ecs_auth_service" {
  source = "./ecs_service"
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
  rds_db_arn            = module.rds_auth_service.rds_db_arn
}

module "rds_auth_service" {
  source             = "./rds"
  prefix             = local.prefix
  db_name            = "epb"
  vpc_id             = module.networking.vpc_id
  ecs_cluster_id     = module.ecs_auth_service.ecs_cluster_id
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_ids = module.networking.security_group_ids
}

module "secrets" {
  source = "./secrets"
  prefix = local.prefix
  secrets = {
    "RDS_AUTH_SERVICE_PASSWORD" : module.rds_auth_service.rds_db_password,
    "RDS_AUTH_SERVICE_USERNAME" : module.rds_auth_service.rds_db_username,
    "RDS_AUTH_SERVICE_HOSTNAME" : module.rds_auth_service.rds_db_hostname,
    "RDS_AUTH_SERVICE_PORT" : module.rds_auth_service.rds_db_port,
    "RDS_AUTH_SERVICE_DB_NAME" : module.rds_auth_service.rds_db_name,
    "RDS_AUTH_SERVICE_ENDPOINT" : module.rds_auth_service.rds_db_endpoint
  }
}
