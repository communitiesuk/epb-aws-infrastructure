module "networking" {
  source = "./networking"

  prefix = local.prefix
  region = var.region
}

module "access" {
  source = "./access"

  ci_account_id = var.ci_account_id
}

module "ssl_certificate" {
  source = "./ssl"

  domain_name = var.domain_name
}

# This being on us-east-1 is a requirement for CloudFront to use the SSL certificate
module "cdn_certificate" {
  source = "./ssl"
  providers = {
    aws = aws.us-east
  }

  domain_name = var.domain_name
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

module "secrets" {
  source = "./secrets"

  secrets = {
    "EPB_API_URL" : "http://${module.register_api_application.internal_alb_dns}"
    "EPB_AUTH_SERVER" : "http://${module.auth_application.internal_alb_dns}/auth"
    "EPB_DATA_WAREHOUSE_QUEUES_URI" : module.warehouse_redis.redis_uri
    "EPB_QUEUES_URI" : module.warehouse_redis.redis_uri
    "EPB_UNLEASH_URI" : "http://${module.toggles_application.internal_alb_dns}/api"
    "EPB_WORKER_REDIS_URI" : module.register_sidekiq_redis.redis_uri
    "RDS_API_SERVICE_CONNECTION_STRING" : module.register_api_database.rds_db_connection_string
    "RDS_API_SERVICE_PASSWORD" : module.register_api_database.rds_db_password
    "RDS_API_SERVICE_USERNAME" : module.register_api_database.rds_db_username
    "RDS_AUTH_SERVICE_CONNECTION_STRING" : module.auth_database.rds_db_connection_string
    "RDS_AUTH_SERVICE_PASSWORD" : module.auth_database.rds_db_password
    "RDS_AUTH_SERVICE_USERNAME" : module.auth_database.rds_db_username
    "RDS_TOGGLES_CONNECTION_STRING" : module.toggles_database.rds_db_connection_string
    "RDS_TOGGLES_PASSWORD" : module.toggles_database.rds_db_password
    "RDS_TOGGLES_USERNAME" : module.toggles_database.rds_db_username
    "RDS_WAREHOUSE_CONNECTION_STRING" : module.warehouse_database.rds_db_connection_string
    "RDS_WAREHOUSE_PASSWORD" : module.warehouse_database.rds_db_password
    "RDS_WAREHOUSE_USERNAME" : module.warehouse_database.rds_db_username
    "RDS_TEST_PASSWORD" : module.rds_test.rds_db_password
  }
}

module "parameter_store" {
  source = "./parameter_store"

  parameters = {
    "APP_ENV" : "String"
    "EPB_TEAM_SLACK_URL" : "SecureString"
    "EPB_UNLEASH_AUTH_TOKEN" : "SecureString"
    "FRONTEND_EPB_AUTH_CLIENT_ID" : "SecureString"
    "FRONTEND_EPB_AUTH_CLIENT_SECRET" : "SecureString"
    "JWT_ISSUER" : "SecureString"
    "JWT_SECRET" : "SecureString"
    "LANG" : "String"
    "LOGSTASH_HOST" : "SecureString"
    "LOGSTASH_PORT" : "SecureString"
    "OPEN_DATA_REPORT_TYPE" : "String"
    "OS_DATA_HUB_API_KEY" : "SecureString"
    "RACK_ENV" : "String"
    "SLACK_EPB_BOT_TOKEN" : "SecureString"
    "STAGE" : "String"
    "TOGGLES_SECRET" : "SecureString"
    "VALID_DOMESTIC_SCHEMAS" : "String"
    "VALID_NON_DOMESTIC_SCHEMAS" : "String"
    "WAREHOUSE_EPB_AUTH_CLIENT_ID" : "SecureString"
    "WAREHOUSE_EPB_AUTH_CLIENT_SECRET" : "SecureString"
  }
}

# applications and backing services

module "toggles_database" {
  source = "./rds"

  prefix                = "${local.prefix}-toggles"
  db_name               = "unleash"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.toggles_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1
  storage_size          = 5
  instance_class        = "db.t3.micro"
}

module "toggles_application" {
  source = "./application"

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
  additional_task_role_policy_arns = { "RDS_access" : module.toggles_database.rds_full_access_policy_arn }
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

module "auth_application" {
  source = "./application"

  prefix                = "${local.prefix}-auth"
  region                = var.region
  container_port        = 80
  egress_ports          = [80, 443, 5432]
  environment_variables = []
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"]
  }
  parameters                       = module.parameter_store.parameter_arns
  vpc_id                           = module.networking.vpc_id
  private_subnet_ids               = module.networking.private_subnet_ids
  health_check_path                = "/auth/healthcheck"
  additional_task_role_policy_arns = { "RDS_access" : module.auth_database.rds_full_access_policy_arn }
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

module "auth_database" {
  source = "./rds"

  prefix                = "${local.prefix}-auth"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.auth_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1 # to prevent weird behaviour when the backup window is set to 0
  storage_size          = 5
  instance_class        = "db.t3.micro"
}

module "rds_test" {
  source = "./rds"

  prefix                = "${local.prefix}-test"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.auth_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1 # to prevent weird behaviour when the backup window is set to 0
  storage_size          = 5
  instance_class        = "db.t3.micro"
}

module "register_api_application" {
  source = "./application"

  prefix                = "${local.prefix}-reg-api"
  region                = var.region
  container_port        = 80
  egress_ports          = [80, 443, 5432, local.redis_port]
  environment_variables = []
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"],
    "EPB_DATA_WAREHOUSE_QUEUES_URI" : module.secrets.secret_arns["EPB_DATA_WAREHOUSE_QUEUES_URI"]
  }
  parameters         = module.parameter_store.parameter_arns
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = "/healthcheck"
  additional_task_role_policy_arns = {
    "RDS_access" : module.register_api_database.rds_full_access_policy_arn,
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

module "register_api_database" {
  source = "./aurora_rds"

  prefix                = "${local.prefix}-reg-api"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.register_api_application.ecs_security_group_id, module.register_sidekiq_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = var.storage_backup_period
  instance_class        = "db.t3.medium"
}

module "register_sidekiq_application" {
  source = "./application"

  prefix                = "${local.prefix}-reg-sidekiq"
  region                = var.region
  container_port        = 80
  egress_ports          = [80, 443, 5432, local.redis_port]
  environment_variables = []
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"],
    "EPB_WORKER_REDIS_URI" : module.secrets.secret_arns["EPB_WORKER_REDIS_URI"]
  }
  parameters         = module.parameter_store.parameter_arns
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = "/healthcheck"
  additional_task_role_policy_arns = {
    "RDS_access" : module.register_api_database.rds_full_access_policy_arn,
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  create_internal_alb           = false
}

module "register_sidekiq_redis" {
  source = "./elasticache"

  prefix                        = "${local.prefix}-reg-sidekiq"
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  redis_port                    = local.redis_port
  subnet_ids                    = module.networking.private_subnet_ids
  vpc_id                        = module.networking.vpc_id
}

module "frontend_application" {
  source = "./application"

  prefix                = "${local.prefix}-frontend"
  region                = var.region
  container_port        = 80
  egress_ports          = [80, 443, 5432]
  environment_variables = []
  secrets = {
    "EPB_API_URL" : module.secrets.secret_arns["EPB_API_URL"],
    "EPB_AUTH_SERVER" : module.secrets.secret_arns["EPB_AUTH_SERVER"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"]
  }
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

module "warehouse_application" {
  source = "./application"

  prefix                = "${local.prefix}-warehouse"
  region                = var.region
  container_port        = 80
  egress_ports          = [80, 443, 5432, local.redis_port]
  environment_variables = []
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_WAREHOUSE_CONNECTION_STRING"],
    "EPB_API_URL" : module.secrets.secret_arns["EPB_API_URL"],
    "EPB_AUTH_SERVER" : module.secrets.secret_arns["EPB_AUTH_SERVER"],
    "EPB_QUEUES_URI" : module.secrets.secret_arns["EPB_QUEUES_URI"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"]
  }
  parameters = merge(module.parameter_store.parameter_arns, {
    "EPB_AUTH_CLIENT_ID" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_ID"],
    "EPB_AUTH_CLIENT_SECRET" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_SECRET"]
  })
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = null
  additional_task_role_policy_arns = {
    "RDS_access" : module.register_api_database.rds_full_access_policy_arn
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  create_internal_alb           = false
}

module "warehouse_database" {
  source = "./aurora_rds"

  prefix                = "${local.prefix}-warehouse"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.warehouse_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = var.storage_backup_period
  instance_class        = "db.t3.medium"
}

module "warehouse_redis" {
  source = "./elasticache"

  prefix                        = "${local.prefix}-warehouse"
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  redis_port                    = local.redis_port
  subnet_ids                    = module.networking.private_subnet_ids
  vpc_id                        = module.networking.vpc_id
}

module "bastion" {
  source = "./bastion"

  subnet_id = module.networking.private_subnet_ids[0]
  vpc_id    = module.networking.vpc_id
  rds_access_policy_arns = {
    "Auth" : module.auth_database.rds_full_access_policy_arn
    "API" : module.register_api_database.rds_full_access_policy_arn
    "Toggles" : module.toggles_database.rds_full_access_policy_arn
    "Warehouse" : module.warehouse_database.rds_full_access_policy_arn
  }
}

# logging and alerts

module "logging" {
  source = "./logging"

  prefix      = local.prefix
  environment = var.environment
}

module "alerts" {
  source = "./alerts"

  prefix = local.prefix

  ecs_services = {
    api_service = {
      cluster_name = module.register_api_application.ecs_cluster_name
      service_name = module.register_api_application.ecs_service_name
    },
    auth_service = {
      cluster_name = module.auth_application.ecs_cluster_name
      service_name = module.auth_application.ecs_service_name
    },
    frontend = {
      cluster_name = module.frontend_application.ecs_cluster_name
      service_name = module.frontend_application.ecs_service_name
    },
    toggles = {
      cluster_name = module.toggles_application.ecs_cluster_name
      service_name = module.toggles_application.ecs_service_name
    },
    sidekiq_service = {
      cluster_name = module.register_sidekiq_application.ecs_cluster_name
      service_name = module.register_sidekiq_application.ecs_service_name
    },
    warehouse = {
      cluster_name = module.warehouse_application.ecs_cluster_name
      service_name = module.warehouse_application.ecs_service_name
    },
  }

  rds_instances = {
    auth_service = module.auth_database.rds_instance_identifier
    toggles      = module.toggles_database.rds_instance_identifier
  }

  rds_clusters = {
    warehouse   = module.warehouse_database.rds_cluster_identifier
    api_service = module.register_api_database.rds_cluster_identifier
  }

  albs = {
    auth                  = module.auth_application.front_door_alb_arn_suffix
    auth_internal         = module.auth_application.internal_alb_arn_suffix
    register_api          = module.register_api_application.front_door_alb_arn_suffix
    register_api_internal = module.register_api_application.internal_alb_arn_suffix
    toggles               = module.toggles_application.front_door_alb_arn_suffix
    toggles_internal      = module.toggles_application.internal_alb_arn_suffix
    frontend              = module.frontend_application.front_door_alb_arn_suffix
  }

}

# migration applications

module "data_migration_shared" {
  source = "./data_migration_shared"

  prefix = "${local.prefix}-data-migration"
}

module "data_migration_auth_application" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-auth-migration"
  region                              = var.region
  rds_full_access_policy_arn          = module.auth_database.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"]
  backup_file                         = "epbr-auth-integration.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group
}

module "data_migration_api_application" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-api-migration"
  region                              = var.region
  rds_full_access_policy_arn          = module.register_api_database.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"]
  backup_file                         = "epbr-api-integration.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group

  minimum_cpu       = 1024
  minimum_memory_mb = 4096
}

module "data_migration_toggles_application" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-toggles-migration"
  region                              = var.region
  rds_full_access_policy_arn          = module.toggles_database.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_TOGGLES_CONNECTION_STRING"]
  backup_file                         = "epbr-toggles-integration.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group
}

module "data_migration_warehouse_application" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-warehouse-migration"
  region                              = var.region
  rds_full_access_policy_arn          = module.warehouse_database.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_WAREHOUSE_CONNECTION_STRING"]
  backup_file                         = "epbr-data-warehouse-integration.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group

  minimum_cpu       = 1024
  minimum_memory_mb = 2048
}
