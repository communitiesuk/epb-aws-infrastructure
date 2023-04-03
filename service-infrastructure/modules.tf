module "networking" {
  source = "./networking"

  prefix = local.prefix
  region = var.region
}

module "logging" {
  source = "./logging"

  prefix      = local.prefix
  environment = var.environment
}

module "access" {
  source = "./access"

  ci_account_id = var.ci_account_id
}

module "ssl_certificate" {
  source = "./ssl"

  domain_name = "*.${var.domain_name}"
}

# This being on us-east-1 is a requirement for CloudFront to use the SSL certificate
module "cdn_certificate" {
  source = "./ssl"
  providers = {
    aws = aws.us-east
  }

  domain_name = "*.${var.domain_name}"
}

# This being on us-east-1 is a requirement for CloudFront to use the WAF
module "waf" {
  source = "./waf"
  providers = {
    aws = aws.us-east
  }

  prefix                   = local.prefix
  forbidden_ip_addresses   = []
  forbidden_ipv6_addresses = []
}

module "ecs_auth_service" {
  source = "./service"

  prefix         = "${local.prefix}-auth-service"
  region         = var.region
  container_port = 80
  egress_ports   = [80, 443, 5432]
  environment_variables = [
    {
      "name"  = "EPB_UNLEASH_URI"
      "value" = "http://${module.ecs_toggles.internal_alb_dns}/api"
    }
  ]
  secrets                          = { "DATABASE_URL" : module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"] }
  parameters                       = module.parameter_store.parameter_arns
  vpc_id                           = module.networking.vpc_id
  private_subnet_ids               = module.networking.private_subnet_ids
  health_check_path                = "/auth/healthcheck"
  additional_task_role_policy_arns = { "RDS_access" : module.rds_auth_service.rds_full_access_policy_arn }
  aws_cloudwatch_log_group_id      = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name    = module.logging.cloudwatch_log_group_name
  logs_bucket_name                 = module.logging.logs_bucket_name
  logs_bucket_url                  = module.logging.logs_bucket_url
  front_door_config = {
    aws_ssl_certificate_arn        = module.ssl_certificate.certificate_arn
    aws_cdn_certificate_arn        = module.cdn_certificate.certificate_arn
    cdn_allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods             = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl                  = 0
    cdn_aliases                    = toset(["auth${var.subdomain_suffix}.${var.domain_name}"])
    forbidden_ip_addresses_acl_arn = module.waf.forbidden_ip_addresses_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
  }
}

module "rds_auth_service" {
  source = "./rds"

  prefix                = "${local.prefix}-auth-service"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.ecs_auth_service.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1 # to prevent weird behaviour when the backup window is set to 0
  storage_size          = 5
  instance_class        = "db.t3.micro"
}

module "ecs_api_service" {
  source = "./service"

  prefix         = "${local.prefix}-api-service"
  region         = var.region
  container_port = 80
  egress_ports   = [80, 443, 5432, local.redis_port]
  environment_variables = [
    {
      name  = "EPB_UNLEASH_URI"
      value = "http://${module.ecs_toggles.internal_alb_dns}/api"
    },
    {
      name  = "EPB_DATA_WAREHOUSE_QUEUES_URI"
      value = module.redis_warehouse.redis_uri
    }
  ]
  secrets            = { "DATABASE_URL" : module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"] }
  parameters         = module.parameter_store.parameter_arns
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = "/healthcheck"
  additional_task_role_policy_arns = {
    "RDS_access" : module.rds_api_service.rds_full_access_policy_arn,
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  front_door_config = {
    aws_ssl_certificate_arn        = module.ssl_certificate.certificate_arn
    aws_cdn_certificate_arn        = module.cdn_certificate.certificate_arn
    cdn_allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods             = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl                  = 0
    cdn_aliases                    = toset(["api${var.subdomain_suffix}.${var.domain_name}"])
    forbidden_ip_addresses_acl_arn = module.waf.forbidden_ip_addresses_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
  }
}

module "ecs_sidekiq_service" {
  source = "./service"

  prefix         = "${local.prefix}-sidekiq"
  region         = var.region
  container_port = 80
  egress_ports   = [80, 443, 5432, local.redis_port]
  environment_variables = [
    {
      name  = "EPB_UNLEASH_URI"
      value = "http://${module.ecs_toggles.internal_alb_dns}/api"
    },
    {
      name  = "EPB_WORKER_REDIS_URI"
      value = module.redis_sidekiq.redis_uri
    },
  ]
  secrets            = { "DATABASE_URL" : module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"] }
  parameters         = module.parameter_store.parameter_arns
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = "/healthcheck"
  additional_task_role_policy_arns = {
    "RDS_access" : module.rds_api_service.rds_full_access_policy_arn,
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  create_internal_alb           = false
}

module "redis_sidekiq" {
  source = "./elasticache"

  prefix                        = "${local.prefix}-sidekiq"
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  redis_port                    = local.redis_port
  subnet_ids                    = module.networking.private_subnet_ids
  vpc_id                        = module.networking.vpc_id
}

module "rds_api_service" {
  source = "./aurora_rds"

  prefix                = "${local.prefix}-api-service"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.ecs_api_service.ecs_security_group_id, module.ecs_sidekiq_service.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = var.storage_backup_period
  instance_class        = "db.t3.medium"
}

module "ecs_warehouse" {
  source = "./service"

  prefix         = "${local.prefix}-warehouse"
  region         = var.region
  container_port = 80
  egress_ports   = [80, 443, 5432, local.redis_port]
  environment_variables = [
    {
      name  = "EPB_API_URL"
      value = "http://${module.ecs_api_service.internal_alb_dns}"
    },
    {
      "name"  = "EPB_AUTH_SERVER"
      "value" = "http://${module.ecs_auth_service.internal_alb_dns}/auth"
    },
    {
      name  = "EPB_QUEUES_URI"
      value = module.redis_warehouse.redis_uri
    },
    {
      name  = "EPB_UNLEASH_URI"
      value = "http://${module.ecs_toggles.internal_alb_dns}/api"
    },
  ]
  secrets = { "DATABASE_URL" : module.secrets.secret_arns["RDS_WAREHOUSE_CONNECTION_STRING"] }
  parameters = merge(module.parameter_store.parameter_arns, {
    "EPB_AUTH_CLIENT_ID" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_ID"],
    "EPB_AUTH_CLIENT_SECRET" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_SECRET"]
  })
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = null
  additional_task_role_policy_arns = {
    "RDS_access" : module.rds_api_service.rds_full_access_policy_arn
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  create_internal_alb           = false
}

module "rds_warehouse" {
  source = "./aurora_rds"

  prefix                = "${local.prefix}-warehouse"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.ecs_warehouse.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = var.storage_backup_period
  instance_class        = "db.t3.medium"
}

module "redis_warehouse" {
  source = "./elasticache"

  prefix                        = "${local.prefix}-warehouse"
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  redis_port                    = local.redis_port
  subnet_ids                    = module.networking.private_subnet_ids
  vpc_id                        = module.networking.vpc_id
}

module "ecs_toggles" {
  source = "./service"

  prefix                = "${local.prefix}-toggles"
  region                = var.region
  container_port        = 4242
  egress_ports          = [80, 443, 5432]
  environment_variables = []
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_TOGGLES_CONNECTION_STRING"],
  }
  parameters                       = module.parameter_store.parameter_arns
  vpc_id                           = module.networking.vpc_id
  private_subnet_ids               = module.networking.private_subnet_ids
  health_check_path                = "/health"
  additional_task_role_policy_arns = { "RDS_access" : module.rds_toggles.rds_full_access_policy_arn }
  aws_cloudwatch_log_group_id      = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name    = module.logging.cloudwatch_log_group_name
  logs_bucket_name                 = module.logging.logs_bucket_name
  logs_bucket_url                  = module.logging.logs_bucket_url
  front_door_config = {
    aws_ssl_certificate_arn        = module.ssl_certificate.certificate_arn
    aws_cdn_certificate_arn        = module.cdn_certificate.certificate_arn
    cdn_allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods             = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl                  = 0
    cdn_aliases                    = toset(["toggles${var.subdomain_suffix}.${var.domain_name}"])
    forbidden_ip_addresses_acl_arn = module.waf.forbidden_ip_addresses_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
  }
}

module "rds_toggles" {
  source = "./rds"

  prefix                = "${local.prefix}-toggles"
  db_name               = "unleash"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.ecs_toggles.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1
  storage_size          = 5
  instance_class        = "db.t3.micro"
}

module "frontend" {
  source = "./service"

  prefix         = "${local.prefix}-frontend"
  region         = var.region
  container_port = 80
  egress_ports   = [80, 443, 5432]
  environment_variables = [
    {
      name  = "EPB_API_URL"
      value = "http://${module.ecs_api_service.internal_alb_dns}"
    },
    {
      name  = "EPB_AUTH_SERVER"
      value = "http://${module.ecs_auth_service.internal_alb_dns}/auth"
    },
    {
      name  = "EPB_UNLEASH_URI"
      value = "http://${module.ecs_toggles.internal_alb_dns}/api"
    }
  ]
  secrets = {}
  parameters = merge(module.parameter_store.parameter_arns, {
    "EPB_AUTH_CLIENT_ID" : module.parameter_store.parameter_arns["FRONTEND_EPB_AUTH_CLIENT_ID"],
    "EPB_AUTH_CLIENT_SECRET" : module.parameter_store.parameter_arns["FRONTEND_EPB_AUTH_CLIENT_SECRET"]
  })
  vpc_id                           = module.networking.vpc_id
  private_subnet_ids               = module.networking.private_subnet_ids
  health_check_path                = "/healthcheck"
  additional_task_role_policy_arns = {}
  aws_cloudwatch_log_group_id      = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name    = module.logging.cloudwatch_log_group_name
  logs_bucket_name                 = module.logging.logs_bucket_name
  logs_bucket_url                  = module.logging.logs_bucket_url
  create_internal_alb              = false
  front_door_config = {
    aws_ssl_certificate_arn = module.ssl_certificate.certificate_arn
    aws_cdn_certificate_arn = module.cdn_certificate.certificate_arn
    cdn_allowed_methods     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods      = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl           = 60 # 1 minute
    cdn_aliases = toset([
      "find-energy-certificate${var.subdomain_suffix}.${var.domain_name}",
      "getting-new-energy-certificate${var.subdomain_suffix}.${var.domain_name}"
    ])
    forbidden_ip_addresses_acl_arn = module.waf.forbidden_ip_addresses_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
  }
}

module "secrets" {
  source = "./secrets"

  secrets = {
    "RDS_AUTH_SERVICE_PASSWORD" : module.rds_auth_service.rds_db_password
    "RDS_AUTH_SERVICE_USERNAME" : module.rds_auth_service.rds_db_username
    "RDS_AUTH_SERVICE_CONNECTION_STRING" : module.rds_auth_service.rds_db_connection_string
    "RDS_API_SERVICE_PASSWORD" : module.rds_api_service.rds_db_password
    "RDS_API_SERVICE_USERNAME" : module.rds_api_service.rds_db_username
    "RDS_API_SERVICE_CONNECTION_STRING" : module.rds_api_service.rds_db_connection_string
    "RDS_WAREHOUSE_PASSWORD" : module.rds_warehouse.rds_db_password
    "RDS_WAREHOUSE_USERNAME" : module.rds_warehouse.rds_db_username
    "RDS_WAREHOUSE_CONNECTION_STRING" : module.rds_warehouse.rds_db_connection_string
    "RDS_TOGGLES_CONNECTION_STRING" : module.rds_toggles.rds_db_connection_string
    "RDS_TOGGLES_PASSWORD" : module.rds_toggles.rds_db_password
    "RDS_TOGGLES_USERNAME" : module.rds_toggles.rds_db_username
  }
}

module "parameter_store" {
  source = "./parameter_store"

  parameters = {
    "JWT_ISSUER" : "SecureString"
    "JWT_SECRET" : "SecureString"
    "LANG" : "String"
    "VALID_DOMESTIC_SCHEMAS" : "String"
    "VALID_NON_DOMESTIC_SCHEMAS" : "String"
    "STAGE" : "String"
    "FRONTEND_EPB_AUTH_CLIENT_ID" : "SecureString"
    "FRONTEND_EPB_AUTH_CLIENT_SECRET" : "SecureString"
    "WAREHOUSE_EPB_AUTH_CLIENT_ID" : "SecureString"
    "WAREHOUSE_EPB_AUTH_CLIENT_SECRET" : "SecureString"
    "EPB_UNLEASH_AUTH_TOKEN" : "SecureString"
    "TOGGLES_SECRET" : "SecureString"
    "LOGSTASH_HOST" : "SecureString"
    "LOGSTASH_PORT" : "SecureString"
    "RACK_ENV" : "String"
    "APP_ENV" : "String"
    "EPB_TEAM_SLACK_URL" : "SecureString"
    "OPEN_DATA_REPORT_TYPE" : "String"
    "OS_DATA_HUB_API_KEY" : "SecureString"
    "SLACK_EPB_BOT_TOKEN" : "SecureString"
  }
}

module "bastion" {
  source = "./bastion"

  subnet_id = module.networking.private_subnet_ids[0]
  vpc_id    = module.networking.vpc_id
  rds_access_policy_arns = {
    "Auth" : module.rds_auth_service.rds_full_access_policy_arn
    "API" : module.rds_api_service.rds_full_access_policy_arn
    "Toggles" : module.rds_toggles.rds_full_access_policy_arn
    "Warehouse" : module.rds_warehouse.rds_full_access_policy_arn
  }
}

module "data_migration_shared" {
  source = "./data_migration_shared"

  prefix = "${local.prefix}-data-migration"
}

module "data_migration_auth_service" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-auth-migration"
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

module "data_migration_toggles" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-toggles-migration"
  region                              = var.region
  rds_full_access_policy_arn          = module.rds_toggles.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_TOGGLES_CONNECTION_STRING"]
  backup_file                         = "epbr-toggles-integration.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group
}

module "data_migration_warehouse" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-warehouse-migration"
  region                              = var.region
  rds_full_access_policy_arn          = module.rds_warehouse.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_WAREHOUSE_CONNECTION_STRING"]
  backup_file                         = "epbr-data-warehouse-integration.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group

  minimum_cpu       = 1024
  minimum_memory_mb = 2048
}
