module "networking" {
  source = "./networking"
  prefix = local.prefix
  region = var.region
  #  to be updated when we have the containers set up
  container_port = "55555"
}

module "logging" {
  source      = "./logging"
  prefix      = local.prefix
  environment = var.environment
}

module "ecs_auth_service" {
  source                              = "./ecs_service"
  prefix                              = "${local.prefix}-auth-service"
  environment                         = var.environment
  region                              = var.region
  container_port                      = "80"
  environment_variables               = []
  secrets                             = merge(module.parameter_store.parameter_arns, { "DATABASE_URL" : module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"] })
  vpc_id                              = module.networking.vpc_id
  private_subnet_ids                  = module.networking.private_subnet_ids
  public_subnet_ids                   = module.networking.public_subnet_ids
  security_group_ids                  = module.networking.security_group_ids
  health_check_path                   = "/auth/healthcheck"
  rds_db_arn                          = module.rds_auth_service.rds_db_arn
  aws_cloudwatch_log_group_id         = module.logging.cloudwatch_log_group_id
}

module "rds_auth_service" {
  source                = "./rds"
  prefix                = "${local.prefix}-auth-service"
  db_name               = "epb"
  engine                = "postgres"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = concat(module.networking.security_group_ids, [module.bastion.security_group_id])
  storage_backup_period = var.storage_backup_period
  storage_size          = 5
  instance_class = "db.t3.micro"
}

module "ecs_api_service" {
  source                              = "./ecs_service"
  prefix                              = "${local.prefix}-api-service"
  environment                         = var.environment
  region                              = var.region
  container_port                      = "80"
  environment_variables               = []
  secrets                             = merge(module.parameter_store.parameter_arns, { "DATABASE_URL" : module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"] })
  vpc_id                              = module.networking.vpc_id
  private_subnet_ids                  = module.networking.private_subnet_ids
  public_subnet_ids                   = module.networking.public_subnet_ids
  security_group_ids                  = module.networking.security_group_ids
  health_check_path                   = "/healthcheck"
  rds_db_arn                          = module.rds_api_service.rds_db_arn
  aws_cloudwatch_log_group_id         = module.logging.cloudwatch_log_group_id
}

module "rds_api_service" {
  source                = "./rds"
  prefix                = "${local.prefix}-api-service"
  db_name               = "epb"
  engine                = "aurora-postgresql"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = concat(module.networking.security_group_ids, [module.bastion.security_group_id])
  storage_backup_period = var.storage_backup_period
  storage_size          = 100
  instance_class = "db.t3.medium"
}

module "secrets" {
  source = "./secrets"
  prefix = local.prefix
  secrets = {
    "RDS_AUTH_SERVICE_PASSWORD" : module.rds_auth_service.rds_db_password,
    "RDS_AUTH_SERVICE_USERNAME" : module.rds_auth_service.rds_db_username,
    "RDS_AUTH_SERVICE_CONNECTION_STRING" : module.rds_auth_service.rds_db_connection_string,
    "RDS_API_SERVICE_PASSWORD" : module.rds_api_service.rds_db_password,
    "RDS_API_SERVICE_USERNAME" : module.rds_api_service.rds_db_username,
    "RDS_API_SERVICE_CONNECTION_STRING" : module.rds_api_service.rds_db_connection_string
  }
}

module "parameter_store" {
  source = "./parameter_store"
  parameters = [
    {
      name  = "JWT_ISSUER"
      type  = "String"
      value = "placeholder"
    },
    {
      name  = "JWT_SECRET"
      type  = "String"
      value = "placeholder"
    },
    {
      name = "LANG"
      type  = "String"
      value = "placeholder"
    },
    {
      name  = "EPB_UNLEASH_URI"
      type  = "String"
      value = "placeholder"
    },
    {
      name  = "VALID_DOMESTIC_SCHEMAS"
      type  = "String"
      value = "placeholder"
    },
    {
      name  = "VALID_NON_DOMESTIC_SCHEMAS"
      type  = "String"
      value = "placeholder"
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

module "bastion" {
  source             = "./bastion"
  subnet_id          = module.networking.private_subnet_ids[0]
  vpc_id             = module.networking.vpc_id
  iam_policy_rds_arn = module.ecs_auth_service.iam_policy_rds_arn
}
