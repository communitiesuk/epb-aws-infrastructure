locals {
  db_subnet = var.environment == "stag" ? module.networking.private_subnet_group_name : module.networking.private_db_subnet_group_name
}


module "account_security" {
  source = "./account_security"
}

module "networking" {
  source                    = "./networking"
  prefix                    = local.prefix
  region                    = var.region
  vpc_cidr_block            = var.vpc_cidr_block
  pass_vpc_cidr             = var.pass_vpc_cidr
  vpc_peering_connection_id = var.vpc_peering_connection_id
}

module "access" {
  source        = "./access"
  ci_account_id = var.ci_account_id
}

module "ssl_certificate" {
  source = "./ssl"

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
}

# This being on us-east-1 is a requirement for CloudFront to use the SSL certificate
module "cdn_certificate" {
  source = "./ssl"
  providers = {
    aws = aws.us-east
  }

  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
}


# This being on us-east-1 is a requirement for CloudFront to use the WAF
module "waf" {
  source = "./waf"
  providers = {
    aws = aws.us-east
  }
  environment              = var.environment
  prefix                   = local.prefix
  forbidden_ip_addresses   = [for ip in var.banned_ip_addresses : ip["ip_address"]]
  forbidden_ipv6_addresses = []
}


module "secrets" {
  source = "./secrets"

  secrets = {
    "EPB_API_URL" : "https://${module.register_api_application.internal_alb_name}.${var.domain_name}:443"
    "EPB_AUTH_SERVER" : "https://${module.auth_application.internal_alb_name}.${var.domain_name}:443/auth"
    "EPB_DATA_WAREHOUSE_QUEUES_URI" : module.warehouse_redis.redis_uri
    "EPB_QUEUES_URI" : module.warehouse_redis.redis_uri
    "EPB_UNLEASH_URI" : "https://${module.toggles_application.internal_alb_name}.${var.domain_name}:443/api"
    "EPB_WORKER_REDIS_URI" : module.register_sidekiq_redis.redis_uri
    "ODE_BUCKET_NAME" : module.open_data_export.open_data_export_bucket_name
    "ODE_BUCKET_ACCESS_KEY" : module.open_data_export.open_data_team_s3_access_key
    "ODE_BUCKET_SECRET" : module.open_data_export.open_data_team_s3_secret
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
    "RDS_PGLOGICAL_TEST_CONNECTION_STRING" : module.pglogical_test_database.rds_db_connection_string
    "RDS_PGLOGICAL_TEST_PASSWORD" : module.pglogical_test_database.rds_db_password
    "RDS_PGLOGICAL_TEST_USERNAME" : module.pglogical_test_database.rds_db_username
  }
}

module "parameter_store" {
  source = "./parameter_store"
  parameters = {
    "APP_ENV" : {
      type  = "String"
      value = var.parameters["APP_ENV"]
    }
    DOMESTIC_APPROVED_SOFTWARE : {
      type  = "String"
      value = var.parameters["DOMESTIC_APPROVED_SOFTWARE"]
    }
    EPB_API_DOCS_URL : {
      type  = "String"
      value = lookup(var.parameters, "EPB_API_DOCS_URL", "https://api-docs.epcregisters.net")
    }
    "EPB_UNLEASH_AUTH_TOKEN" : {
      type  = "SecureString"
      value = var.parameters["EPB_UNLEASH_AUTH_TOKEN"]
    }
    "FRONTEND_EPB_AUTH_CLIENT_ID" : {
      type  = "SecureString"
      value = var.parameters["FRONTEND_EPB_AUTH_CLIENT_ID"]
    }
    "FRONTEND_EPB_AUTH_CLIENT_SECRET" : {
      type  = "SecureString"
      value = var.parameters["FRONTEND_EPB_AUTH_CLIENT_SECRET"]
    }
    "JWT_ISSUER" : {
      type  = "SecureString"
      value = var.parameters["JWT_ISSUER"]
    }
    "JWT_SECRET" : {
      type  = "SecureString"
      value = var.parameters["JWT_SECRET"]
    }
    "LANG" : {
      type  = "String"
      value = var.parameters["LANG"]
    }
    "LOGSTASH_HOST" : {
      type  = "SecureString"
      value = var.parameters["LOGSTASH_HOST"]
    }
    "LOGSTASH_PORT" : {
      type  = "SecureString"
      value = var.parameters["LOGSTASH_PORT"]
    }
    "OPEN_DATA_REPORT_TYPE" : {
      type  = "String"
      value = var.parameters["OPEN_DATA_REPORT_TYPE"]
    }
    "OS_DATA_HUB_API_KEY" : {
      type  = "SecureString"
      value = var.parameters["OS_DATA_HUB_API_KEY"]
    }
    NON_DOMESTIC_APPROVED_SOFTWARE : {
      type  = "String"
      value = var.parameters["NON_DOMESTIC_APPROVED_SOFTWARE"]
      tier  = "Advanced"
    }
    "RACK_ENV" : {
      type  = "String"
      value = var.parameters["RACK_ENV"]
    }
    "RAILS_ENV" : {
      type  = "String"
      value = var.parameters["RAILS_ENV"]
    }
    "SENTRY_DSN_AUTH_SERVER" : {
      type  = "SecureString"
      value = var.parameters["SENTRY_DSN_AUTH_SERVER"]
    }
    "SENTRY_DSN_DATA_WAREHOUSE" : {
      type  = "SecureString"
      value = var.parameters["SENTRY_DSN_DATA_WAREHOUSE"]
    }
    "SENTRY_DSN_REGISTER_API" : {
      type  = "SecureString"
      value = var.parameters["SENTRY_DSN_REGISTER_API"]
    }
    "SENTRY_DSN_REGISTER_WORKER" : {
      type  = "SecureString"
      value = var.parameters["SENTRY_DSN_REGISTER_WORKER"]
    }
    "SENTRY_DSN_FRONTEND" : {
      type  = "SecureString"
      value = var.parameters["SENTRY_DSN_FRONTEND"]
    }
    "SLACK_EPB_BOT_TOKEN" : {
      type  = "SecureString"
      value = var.parameters["SLACK_EPB_BOT_TOKEN"]
    }
    "STAGE" : {
      type  = "String"
      value = var.parameters["STAGE"]
    }
    "STATIC_START_PAGE_FINDING_EN" : {
      type  = "String"
      value = var.parameters["STATIC_START_PAGE_FINDING_EN"]
    }
    "STATIC_START_PAGE_FINDING_CY" : {
      type  = "String"
      value = var.parameters["STATIC_START_PAGE_FINDING_CY"]
    }
    "STATIC_START_PAGE_GETTING_EN" : {
      type  = "String"
      value = var.parameters["STATIC_START_PAGE_GETTING_EN"]
    }
    "STATIC_START_PAGE_GETTING_CY" : {
      type  = "String"
      value = var.parameters["STATIC_START_PAGE_GETTING_CY"]
    }
    "TOGGLES_SECRET" : {
      type  = "SecureString"
      value = var.parameters["TOGGLES_SECRET"]
    }
    "URL_PREFIX" : {
      type  = "String"
      value = var.parameters["URL_PREFIX"]
    }
    "VALID_DOMESTIC_SCHEMAS" : {
      type  = "String"
      value = var.parameters["VALID_DOMESTIC_SCHEMAS"]
    }
    "VALID_NON_DOMESTIC_SCHEMAS" : {
      type  = "String"
      value = var.parameters["VALID_NON_DOMESTIC_SCHEMAS"]
    }
    "WAREHOUSE_EPB_AUTH_CLIENT_ID" : {
      type  = "SecureString"
      value = var.parameters["WAREHOUSE_EPB_AUTH_CLIENT_ID"]
    }
    "WAREHOUSE_EPB_AUTH_CLIENT_SECRET" : {
      type  = "SecureString"
      value = var.parameters["WAREHOUSE_EPB_AUTH_CLIENT_SECRET"]
    }
  }
}

# applications and backing services

module "toggles_database" {
  source = "./rds"

  prefix                = "${local.prefix}-toggles"
  db_name               = "unleash"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = local.db_subnet
  security_group_ids    = [module.toggles_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1
  storage_size          = 5
  instance_class        = var.environment == "intg" ? "db.t3.micro" : "db.m5.large"
  parameter_group_name  = module.parameter_groups.rds_pglogical_target_pg_name
}

module "toggles_application" {
  source = "./application"

  prefix                = "${local.prefix}-toggles"
  region                = var.region
  container_port        = 4242
  egress_ports          = [80, 443, 5432, var.parameters["LOGSTASH_PORT"]]
  environment_variables = []
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_TOGGLES_CONNECTION_STRING"],
  }
  parameters                                 = module.parameter_store.parameter_arns
  vpc_id                                     = module.networking.vpc_id
  fluentbit_ecr_url                          = module.fluentbit_ecr.ecr_url
  private_subnet_ids                         = module.networking.private_subnet_ids
  health_check_path                          = "/health"
  additional_task_execution_role_policy_arns = { "RDS_access" : module.toggles_database.rds_full_access_policy_arn }
  aws_cloudwatch_log_group_id                = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name              = module.logging.cloudwatch_log_group_name
  logs_bucket_name                           = module.logging.logs_bucket_name
  logs_bucket_url                            = module.logging.logs_bucket_url
  internal_alb_config = {
    ssl_certificate_arn = module.ssl_certificate.certificate_arn
  }
  front_door_config = {
    ssl_certificate_arn            = module.ssl_certificate.certificate_arn
    cdn_certificate_arn            = module.cdn_certificate.certificate_arn
    cdn_allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods             = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl                  = 0
    cdn_aliases                    = toset(["toggles.${var.domain_name}"])
    forbidden_ip_addresses_acl_arn = module.waf.forbidden_ip_addresses_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
    path_based_routing_overrides   = []
    extra_lb_target_groups         = 0
  }
}

module "auth_application" {
  source = "./application"

  prefix                = "${local.prefix}-auth"
  region                = var.region
  container_port        = 3001
  egress_ports          = [80, 443, 5432, var.parameters["LOGSTASH_PORT"]]
  environment_variables = []
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"]
  }
  parameters = merge(module.parameter_store.parameter_arns, {
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_AUTH_SERVER"]
  })
  has_exec_cmd_task                          = true
  vpc_id                                     = module.networking.vpc_id
  fluentbit_ecr_url                          = module.fluentbit_ecr.ecr_url
  private_subnet_ids                         = module.networking.private_subnet_ids
  health_check_path                          = "/auth/healthcheck"
  additional_task_execution_role_policy_arns = { "RDS_access" : module.auth_database.rds_full_access_policy_arn }
  aws_cloudwatch_log_group_id                = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name              = module.logging.cloudwatch_log_group_name
  logs_bucket_name                           = module.logging.logs_bucket_name
  logs_bucket_url                            = module.logging.logs_bucket_url
  internal_alb_config = {
    ssl_certificate_arn = module.ssl_certificate.certificate_arn
  }
  front_door_config = {
    ssl_certificate_arn            = module.ssl_certificate.certificate_arn
    cdn_certificate_arn            = module.cdn_certificate.certificate_arn
    cdn_allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods             = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl                  = 0
    cdn_aliases                    = toset(["auth.${var.domain_name}"])
    forbidden_ip_addresses_acl_arn = module.waf.forbidden_ip_addresses_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
    path_based_routing_overrides   = []
    extra_lb_target_groups         = 1
  }
}

module "auth_database" {
  source = "./rds"

  prefix                = "${local.prefix}-auth"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = local.db_subnet
  security_group_ids    = [module.auth_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1 # to prevent weird behaviour when the backup window is set to 0
  storage_size          = 5
  instance_class        = var.environment == "intg" ? "db.t3.micro" : "db.m5.large"
  parameter_group_name  = module.parameter_groups.rds_pglogical_target_pg_name
}

# Used for testing pglogical replication
module "pglogical_test_database" {
  source = "./rds"

  prefix                = "${local.prefix}-pglogical-test"
  db_name               = "epb"
  vpc_id                = module.networking.vpc_id
  subnet_group_name     = module.networking.private_subnet_group_name
  security_group_ids    = [module.data_migration_shared.postgres_access_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1 # to prevent weird behaviour when the backup window is set to 0
  storage_size          = 1000
  instance_class        = "db.t3.medium"
  parameter_group_name  = var.environment == "intg" ? module.parameter_groups.rds_pglogical_source_pg_name : module.parameter_groups.rds_pglogical_target_pg_name
}

module "register_api_application" {
  source = "./application"

  prefix                = "${local.prefix}-reg-api"
  region                = var.region
  container_port        = 3001
  egress_ports          = [80, 443, 5432, local.redis_port, var.parameters["LOGSTASH_PORT"]]
  environment_variables = []
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"],
    "EPB_DATA_WAREHOUSE_QUEUES_URI" : module.secrets.secret_arns["EPB_DATA_WAREHOUSE_QUEUES_URI"]
  }
  parameters = merge(module.parameter_store.parameter_arns, {
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_REGISTER_API"]
  })
  has_exec_cmd_task  = true
  vpc_id             = module.networking.vpc_id
  fluentbit_ecr_url  = module.fluentbit_ecr.ecr_url
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = "/healthcheck"
  additional_task_execution_role_policy_arns = {
    "RDS_access" : module.register_api_database.rds_full_access_policy_arn,
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  internal_alb_config = {
    ssl_certificate_arn = module.ssl_certificate.certificate_arn
  }
  front_door_config = {
    ssl_certificate_arn            = module.ssl_certificate.certificate_arn
    cdn_certificate_arn            = module.cdn_certificate.certificate_arn
    cdn_allowed_methods            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods             = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl                  = 0
    cdn_aliases                    = toset(["api.${var.domain_name}"])
    forbidden_ip_addresses_acl_arn = module.waf.forbidden_ip_addresses_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
    path_based_routing_overrides = [
      # forward requests for auth tokens to the auth application
      {
        path_pattern     = ["/auth/*"]
        target_group_arn = module.auth_application.front_door_alb_extra_target_group_arns[0]
      }
    ]
    extra_lb_target_groups = 0
  }
  has_responsiveness_scale = var.environment == "intg" ? false : true
}

module "register_api_database" {
  source                        = "./aurora_rds"
  prefix                        = "${local.prefix}-reg-api"
  db_name                       = "epb"
  vpc_id                        = module.networking.vpc_id
  subnet_group_name             = local.db_subnet
  security_group_ids            = var.environment == "prod" ? [module.register_api_application.ecs_security_group_id, module.register_sidekiq_application.ecs_security_group_id, module.bastion.security_group_id, module.reg_api_dms_security_group[0].security_group_id] : [module.register_api_application.ecs_security_group_id, module.register_sidekiq_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period         = var.storage_backup_period
  instance_class                = var.environment == "intg" ? "db.t3.medium" : "db.r5.large"
  cluster_parameter_group_name  = module.parameter_groups.aurora_pglogical_target_pg_name
  instance_parameter_group_name = module.parameter_groups.rds_pglogical_target_pg_name
  pass_vpc_cidr                 = var.environment == "prod" ? [var.pass_vpc_cidr] : []
}

module "register_sidekiq_application" {
  source                = "./application"
  has_exec_cmd_task     = true
  prefix                = "${local.prefix}-reg-sidekiq"
  region                = var.region
  container_port        = 80
  egress_ports          = [80, 443, 5432, local.redis_port, var.parameters["LOGSTASH_PORT"]]
  environment_variables = []
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_API_SERVICE_CONNECTION_STRING"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"],
    "EPB_WORKER_REDIS_URI" : module.secrets.secret_arns["EPB_WORKER_REDIS_URI"],
    "ODE_BUCKET_NAME" : module.secrets.secret_arns["ODE_BUCKET_NAME"]
  }
  parameters = merge(module.parameter_store.parameter_arns, {
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_REGISTER_WORKER"]
  })
  vpc_id             = module.networking.vpc_id
  fluentbit_ecr_url  = module.fluentbit_ecr.ecr_url
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = "/healthcheck"
  additional_task_execution_role_policy_arns = {
    "RDS_access" : module.register_api_database.rds_full_access_policy_arn,
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  additional_task_role_policy_arns = {
    "OpenDataExport_S3_access" : module.open_data_export.open_data_s3_write_access_policy_arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  enable_execute_command        = true
}

module "register_sidekiq_redis" {
  source = "./elasticache"

  prefix                        = "${local.prefix}-reg-sidekiq"
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  redis_port                    = local.redis_port
  subnet_ids                    = module.networking.private_subnet_ids
  subnet_cidr                   = module.networking.private_subnet_cidr
  vpc_id                        = module.networking.vpc_id
}

module "frontend_application" {
  source = "./application"

  prefix                = "${local.prefix}-frontend"
  region                = var.region
  container_port        = 3001
  egress_ports          = [80, 443, 5432, var.parameters["LOGSTASH_PORT"]]
  environment_variables = []
  secrets = {
    "EPB_API_URL" : module.secrets.secret_arns["EPB_API_URL"],
    "EPB_AUTH_SERVER" : module.secrets.secret_arns["EPB_AUTH_SERVER"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"]
  }
  parameters = merge(module.parameter_store.parameter_arns, {
    "EPB_AUTH_CLIENT_ID" : module.parameter_store.parameter_arns["FRONTEND_EPB_AUTH_CLIENT_ID"],
    "EPB_AUTH_CLIENT_SECRET" : module.parameter_store.parameter_arns["FRONTEND_EPB_AUTH_CLIENT_SECRET"]
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_FRONTEND"]
  })
  vpc_id                                     = module.networking.vpc_id
  fluentbit_ecr_url                          = module.fluentbit_ecr.ecr_url
  private_subnet_ids                         = module.networking.private_subnet_ids
  health_check_path                          = "/healthcheck"
  additional_task_execution_role_policy_arns = {}
  aws_cloudwatch_log_group_id                = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name              = module.logging.cloudwatch_log_group_name
  logs_bucket_name                           = module.logging.logs_bucket_name
  logs_bucket_url                            = module.logging.logs_bucket_url
  front_door_config = {
    ssl_certificate_arn = module.ssl_certificate.certificate_arn
    cdn_certificate_arn = module.cdn_certificate.certificate_arn
    cdn_allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods  = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl       = 60 # 1 minute
    cdn_aliases = toset([
      var.find_service_url,
      var.get_service_url
    ])
    forbidden_ip_addresses_acl_arn = module.waf.forbidden_ip_addresses_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
    path_based_routing_overrides   = []
    extra_lb_target_groups         = 0
  }
  has_responsiveness_scale = var.environment == "intg" ? false : true
}

module "warehouse_application" {
  source = "./application"

  prefix                = "${local.prefix}-warehouse"
  region                = var.region
  container_port        = 80
  egress_ports          = [80, 443, 5432, local.redis_port, var.parameters["LOGSTASH_PORT"]]
  environment_variables = []
  has_exec_cmd_task     = true
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
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_DATA_WAREHOUSE"]
  })
  vpc_id             = module.networking.vpc_id
  fluentbit_ecr_url  = module.fluentbit_ecr.ecr_url
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = null
  additional_task_execution_role_policy_arns = {
    "RDS_access" : module.register_api_database.rds_full_access_policy_arn
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  enable_execute_command        = true
}

module "warehouse_database" {
  source                        = "./aurora_rds"
  prefix                        = "${local.prefix}-warehouse"
  db_name                       = "epb"
  vpc_id                        = module.networking.vpc_id
  subnet_group_name             = local.db_subnet
  security_group_ids            = var.environment == "prod" ? [module.warehouse_application.ecs_security_group_id, module.bastion.security_group_id, module.warehouse_dms_security_group[0].security_group_id] : [module.warehouse_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period         = var.storage_backup_period
  instance_class                = var.environment == "intg" ? "db.t3.medium" : "db.r5.large"
  cluster_parameter_group_name  = module.parameter_groups.aurora_pglogical_target_pg_name
  instance_parameter_group_name = module.parameter_groups.rds_pglogical_target_pg_name
  pass_vpc_cidr                 = var.environment == "prod" ? [var.pass_vpc_cidr] : []
}

module "warehouse_redis" {
  source = "./elasticache"

  prefix                        = "${local.prefix}-warehouse"
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  redis_port                    = local.redis_port
  subnet_ids                    = module.networking.private_subnet_ids
  subnet_cidr                   = module.networking.private_subnet_cidr
  vpc_id                        = module.networking.vpc_id
}

module "bastion" {
  source    = "./bastion"
  subnet_id = module.networking.private_subnet_ids[0]
  vpc_id    = module.networking.vpc_id
  rds_access_policy_arns = {
    "Auth" : module.auth_database.rds_full_access_policy_arn
    "API" : module.register_api_database.rds_full_access_policy_arn
    "Toggles" : module.toggles_database.rds_full_access_policy_arn
    "Warehouse" : module.warehouse_database.rds_full_access_policy_arn
  }
}

module "peering_bastion" {
  count                  = var.environment == "prod" ? 1 : 0
  source                 = "./bastion"
  tag                    = "paas_peering_bastion_host"
  name                   = "pass_peering_bastion"
  subnet_id              = module.networking.private_db_subnet_ids[0]
  vpc_id                 = module.networking.vpc_id
  rds_access_policy_arns = {}
  pass_vpc_cidr          = [var.pass_vpc_cidr]
}


# logging and alerts

module "logging" {
  source = "./logging"

  prefix = local.prefix
}

module "fluentbit_ecr" {
  source = "./ecr"

  ecr_repository_name = "${local.prefix}-fluentbit"
}

module "alerts" {
  source = "./alerts"

  prefix                    = local.prefix
  slack_webhook_url         = var.slack_webhook_url
  cloudtrail_log_group_name = module.logging.cloudtrail_log_group_name

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
  vpc_id = module.networking.vpc_id
}

module "data_migration_auth_application" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-auth-migration"
  region                              = var.region
  rds_full_access_policy_arn          = module.auth_database.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_AUTH_SERVICE_CONNECTION_STRING"]
  backup_file                         = "epbr-auth${var.subdomain_suffix}.dump"
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
  backup_file                         = "epbr-api${var.subdomain_suffix}.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group

  ephemeral_storage_gib = 200
  minimum_cpu           = 4096
  minimum_memory_mb     = 16384
}

module "data_migration_toggles_application" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-toggles-migration"
  region                              = var.region
  rds_full_access_policy_arn          = module.toggles_database.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_TOGGLES_CONNECTION_STRING"]
  backup_file                         = "epbr-toggles${var.subdomain_suffix}.dump"
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
  backup_file                         = "epbr-data-warehouse${var.subdomain_suffix}.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group

  minimum_cpu       = 1024
  minimum_memory_mb = 2048
}

module "data_migration_pglogical_test" {
  source = "./data_migration"

  prefix                              = "${local.prefix}-pglogical-test"
  region                              = var.region
  rds_full_access_policy_arn          = module.pglogical_test_database.rds_full_access_policy_arn
  rds_db_connection_string_secret_arn = module.secrets.secret_arns["RDS_PGLOGICAL_TEST_CONNECTION_STRING"]
  backup_file                         = "pglogical-test.dump"
  ecr_repository_url                  = module.data_migration_shared.ecr_repository_url
  backup_bucket_name                  = module.data_migration_shared.backup_bucket_name
  backup_bucket_arn                   = module.data_migration_shared.backup_bucket_arn
  log_group                           = module.data_migration_shared.log_group

  ephemeral_storage_gib = 200
  minimum_cpu           = 4096
  minimum_memory_mb     = 16384
}

module "open_data_export" {
  source = "./open_data_export"
  prefix = "${local.prefix}-open-data-export"
}

module "parameter_groups" {
  source = "./database_parameter_groups"
}
data "aws_caller_identity" "current" {}

module "warehouse_dms_security_group" {
  count         = var.environment == "prod" ? 1 : 0
  source        = "./dms_security_group"
  name          = "data-warehouse"
  pass_vpc_cidr = [var.pass_vpc_cidr]
  vpc_id        = module.networking.vpc_id
}

module "warehouse_dms" {
  count            = var.environment == "prod" ? 1 : 0
  name             = "data-warehouse"
  instance_class   = "dms.r4.2xlarge"
  mapping_file     = "warehouse_mapping.json"
  settings_file    = "warehouse_settings.json"
  source           = "./dms"
  subnet_group_ids = module.networking.private_db_subnet_ids
  target_db_name   = "epb"
  source_db_name   = "rdsbroker_c662864e_a048_4c04_b82e_b4b9ff66d7f4"
  secrets = {
    "TARGET_DB_SECRET" : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:RDS_WAREHOUSE_DB_CREDS-Q64iqb"
    "SOURCE_DB_SECRET" : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:PAAS_WAREHOUSE_DB_CREDS-wyOLe0"
  }
  rds_access_policy_arns = {
    "Warehouse" : module.warehouse_database.rds_full_access_policy_arn
  }
  security_group_id = module.warehouse_dms_security_group[0].security_group_id
}

module "reg_api_dms_security_group" {
  count         = var.environment == "prod" ? 1 : 0
  source        = "./dms_security_group"
  name          = "register-api"
  pass_vpc_cidr = [var.pass_vpc_cidr]
  vpc_id        = module.networking.vpc_id
}

module "register_api_dms" {
  count            = var.environment == "prod" ? 1 : 0
  name             = "register-api"
  instance_class   = "dms.r4.2xlarge"
  mapping_file     = "register_api_mapping.json"
  settings_file    = "register_api_settings.json"
  source           = "./dms"
  subnet_group_ids = module.networking.private_db_subnet_ids
  target_db_name   = "epb"
  source_db_name   = "rdsbroker_ccb1e459_868b_4f78_9757_effdf6d02ce4"
  secrets = {
    "TARGET_DB_SECRET" : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:RDS_REGISTER_API_DB_CREDS-XjQmXL"
    "SOURCE_DB_SECRET" : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:PAAS_REGISTER_API_DB_CREDS-bXaCzS"
  }
  rds_access_policy_arns = {
    "Register_api" : module.register_api_database.rds_full_access_policy_arn
  }
  security_group_id = module.reg_api_dms_security_group[0].security_group_id
}

module "register_api_xml_dms" {
  count            = var.environment == "prod" ? 1 : 0
  name             = "register-api-xml"
  instance_class   = "dms.r4.2xlarge"
  mapping_file     = "register_api_xml_mapping.json"
  settings_file    = "register_api_xml_settings.json"
  source           = "./dms"
  subnet_group_ids = module.networking.private_db_subnet_ids
  target_db_name   = "epb"
  source_db_name   = "rdsbroker_ccb1e459_868b_4f78_9757_effdf6d02ce4"
  secrets = {
    "TARGET_DB_SECRET" : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:RDS_REGISTER_API_DB_CREDS-XjQmXL"
    "SOURCE_DB_SECRET" : "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:PAAS_REGISTER_API_DB_CREDS-bXaCzS"
  }
  rds_access_policy_arns = {
    "Register_api" : module.register_api_database.rds_full_access_policy_arn
  }
  security_group_id = module.reg_api_dms_security_group[0].security_group_id
}