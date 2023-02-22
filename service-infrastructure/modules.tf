module "networking" {
  source = "./networking"

  prefix = local.prefix
  region = var.region
  #  to be updated when we have the containers set up
  container_port = "55555"
}

module "logging" {
  source = "./logging"

  prefix      = local.prefix
  environment = var.environment
}

module "ecs_auth_service" {
  source = "./ecs_service"

  prefix                           = "${local.prefix}-auth-service"
  environment                      = var.environment
  region                           = var.region
  container_port                   = "80"
  environment_variables            = []
  secrets                          = { "DATABASE_URL" : module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"] }
  parameters                       = module.parameter_store.parameter_arns
  vpc_id                           = module.networking.vpc_id
  private_subnet_ids               = module.networking.private_subnet_ids
  public_subnet_ids                = module.networking.public_subnet_ids
  security_group_ids               = module.networking.security_group_ids
  health_check_path                = "/auth/healthcheck"
  additional_task_role_policy_arns = { "RDS_access" : module.rds_auth_service.rds_full_access_policy_arn }
  aws_cloudwatch_log_group_id      = module.logging.cloudwatch_log_group_id
  logs_bucket_name                 = module.logging.logs_bucket_name
}

module "rds_auth_service" {
  source = "./rds"

  prefix                = "${local.prefix}-auth-service"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = concat(module.networking.security_group_ids, [module.bastion.security_group_id])
  storage_backup_period = 1
  storage_size          = 5
  instance_class        = "db.t3.micro"
}

module "ecs_api_service" {
  source = "./ecs_service"

  prefix                           = "${local.prefix}-api-service"
  environment                      = var.environment
  region                           = var.region
  container_port                   = "80"
  environment_variables            = []
  secrets                          = { "DATABASE_URL" : module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"] }
  parameters                       = module.parameter_store.parameter_arns
  vpc_id                           = module.networking.vpc_id
  private_subnet_ids               = module.networking.private_subnet_ids
  public_subnet_ids                = module.networking.public_subnet_ids
  security_group_ids               = module.networking.security_group_ids
  health_check_path                = "/healthcheck"
  additional_task_role_policy_arns = { "RDS_access" : module.rds_api_service.rds_full_access_policy_arn }
  aws_cloudwatch_log_group_id      = module.logging.cloudwatch_log_group_id
  logs_bucket_name                 = module.logging.logs_bucket_name
}

module "rds_api_service" {
  source = "./aurora_rds"

  prefix                = "${local.prefix}-api-service"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = concat(module.networking.security_group_ids, [module.bastion.security_group_id])
  storage_backup_period = var.storage_backup_period
  storage_size          = 100
  instance_class        = "db.t3.medium"
}

module "frontend" {
  source = "./ecs_service"

  prefix                           = "${local.prefix}-frontend"
  environment                      = var.environment
  region                           = var.region
  container_port                   = "80"
  environment_variables            = []
  secrets                          = {}
  parameters                       = module.parameter_store.parameter_arns
  vpc_id                           = module.networking.vpc_id
  private_subnet_ids               = module.networking.private_subnet_ids
  public_subnet_ids                = module.networking.public_subnet_ids
  security_group_ids               = module.networking.security_group_ids
  health_check_path                = "/healhcheck"
  additional_task_role_policy_arns = { }
  aws_cloudwatch_log_group_id      = module.logging.cloudwatch_log_group_id
  logs_bucket_name                 = module.logging.logs_bucket_name
}

module "secrets" {
  source = "./secrets"

  prefix = local.prefix
  region = var.region
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

  parameters = {
    "JWT_ISSUER" : "String",
    "JWT_SECRET" : "String",
    "LANG" : "String",
    "EPB_UNLEASH_URI" : "String",
    "VALID_DOMESTIC_SCHEMAS" : "String",
    "VALID_NON_DOMESTIC_SCHEMAS" : "String"
  }
}


module "bastion" {
  source = "./bastion"

  subnet_id = module.networking.private_subnet_ids[0]
  vpc_id    = module.networking.vpc_id
  rds_access_policy_arns = {
    "Auth" : module.rds_auth_service.rds_full_access_policy_arn,
    "API" : module.rds_api_service.rds_full_access_policy_arn
  }
}

module "data_migration_shared" {
  source = "./data_migration_shared"

  prefix = "${local.prefix}-data-migration"
}

module "data_migration_auth_service" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-auth-migration"
  environment                         = var.environment
  region                              = var.region
  rds_full_access_policy_arn          = module.rds_auth_service.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"]
  backup_file                         = "epbr-auth-integration.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group
}

module "data_migration_api_service" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-api-migration"
  environment                         = var.environment
  region                              = var.region
  rds_full_access_policy_arn          = module.rds_api_service.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"]
  backup_file                         = "epbr-api-integration.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group

  minimum_cpu       = 1024
  minimum_memory_mb = 4096
}