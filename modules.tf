module "networking" {
  source = "./networking"
  prefix = local.prefix
  region = var.region
  #  to be updated when we have the containers set up
  container_port = "55555"
}

module "ecs_auth_service" {
  source                = "./ecs_service"
  prefix                = "${local.prefix}-auth-service"
  environment           = var.environment
  region                = var.region
  container_port        = "80"
  environment_variables = []
  secrets               = merge(module.parameter_store.parameter_arns, { "DATABASE_URL" : module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"] })
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  security_group_ids    = module.networking.security_group_ids
  health_check_path     = "/auth/healthcheck"
  vpc_id                = module.networking.vpc_id
  rds_db_arn            = module.rds_auth_service.rds_db_arn
}

module "rds_auth_service" {
  source             = "./rds"
  prefix             = "${local.prefix}-auth-service"
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
    "RDS_AUTH_SERVICE_CONNECTION_STRING" : module.rds_auth_service.rds_db_connection_string
  }
}

module "parameter_store" {
  source = "./parameter_store"
  parameters = [
    {
      name  = "JWT_ISSUER"
      type  = "String"
      value = "place_holder"
    },
    {
      name  = "JWT_SECRET"
      type  = "String"
      value = "place_holder"
    }
  ]
}

module "data_migration_auth_service" {
  source                              = "./data_migration"
  prefix                              = "${local.prefix}-data-migration"
  environment                         = var.environment
  region                              = var.region
  rds_db_arn                          = module.rds_auth_service.rds_db_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"]
  backup_file                         = "epbr-auth-integration.dump"
}
