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
  rds_db_arn            = module.rds.rds_db_arn
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
  secrets = [
    {
      name  = "RDS_AUTH_SERVICE_PASSWORD"
      value = module.rds_auth_service.rds_db_password
    },
    {
      name  = "RDS_AUTH_SERVICE_USERNAME"
      value = module.rds_auth_service.rds_db_username
    },
    {
      name  = "RDS_AUTH_SERVICE_HOSTNAME"
      value = module.rds_auth_service.rds_db_hostname
    },
    {
      name  = "RDS_AUTH_SERVICE_PORT"
      value = module.rds_auth_service.rds_db_port
    },
    {
      name  = "RDS_AUTH_SERVICE_DB_NAME"
      value = module.rds_auth_service.rds_db_name
    }
  ]
}