locals {
  db_subnet                  = var.environment == "stag" ? module.networking.private_subnet_group_name : module.networking.private_db_subnet_group_name
  rds_snapshot_backup_bucket = "${local.prefix}-rds-snapshot-back-up"
  rds_snapshot_backup_tags = {
    Name      = "${local.prefix}-${local.rds_snapshot_backup_bucket}"
    Terraform = "true"
  }
  security_groups     = [module.warehouse_application.ecs_security_group_id, module.bastion.security_group_id, module.warehouse_scheduled_tasks_application.ecs_security_group_id, module.warehouse_api_application.ecs_security_group_id]
  dwh_security_groups = var.environment == "prod" ? local.security_groups : concat(local.security_groups, [module.data_warehouse_glue[0].glue_security_group_id])
  data_service_url = replace(var.data_service_url, ".digital", "")
}

module "account_security" {
  source = "./account_security"
}

module "data_frontend_delivery" {
  count                          = var.environment == "prod" ? 0 : 1
  source                         = "./data_frontend_delivery"
  prefix                         = local.prefix
  athena_workgroup_arn           = module.data_warehouse_glue[0].athena_workgroup_arn
  glue_s3_bucket_read_policy_arn = module.data_warehouse_glue[0].glue_s3_bucket_read_policy_arn
  output_bucket_write_policy_arn = module.user_data.s3_write_access_policy_arn
  glue_catalog_name              = module.data_warehouse_glue[0].glue_catalog_name
  output_bucket_arn              = module.user_data.bucket_arn
  output_bucket_name             = module.user_data.bucket_name
  notify_environment = {
    "NOTIFY_DATA_API_KEY"              = var.parameters["NOTIFY_DATA_API_KEY"],
    "NOTIFY_DATA_DOWNLOAD_TEMPLATE_ID" = var.parameters["NOTIFY_DATA_TEMPLATE_ID"],
    "NOTIFY_DATA_EMAIL_RECIPIENT"      = var.parameters["NOTIFY_DATA_EMAIL_RECIPIENT"],
    "FRONTEND_URL"                     = "https://${var.data_service_url}",
  }
}

module "networking" {
  source         = "./networking"
  prefix         = local.prefix
  region         = var.region
  vpc_cidr_block = var.vpc_cidr_block
}

module "access" {
  source        = "./access"
  ci_account_id = var.ci_account_id
}

module "ssl_certificate" {
  source                    = "./ssl"
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

module "ssl_certificate_epb_data" {
  source                    = "./ssl"
  domain_name               = local.data_service_url
  subject_alternative_names = []
}

module "cdn_certificate_epb_data" {
  source                    = "./ssl"
  providers = {
    aws = aws.us-east
  }
  domain_name               = local.data_service_url
  subject_alternative_names = []
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
  forbidden_ipv6_addresses = [for ip in var.banned_ipv6_addresses : ip["ip_address"]]
  allowed_ip_addresses     = [for ip in var.permitted_ip_addresses : ip["ip_address"]]
  allowed_ipv6_addresses   = [for ip in var.permitted_ipv6_addresses : ip["ip_address"]]
}

module "onelogin_keys" {
  source = "./tls_key"
  count  = var.environment == "prod" ? 0 : 1
}


resource "random_string" "epb_data_frontend_session_secret" {
  length  = 64
  special = false

  lifecycle {
    prevent_destroy = true
  }
}

module "secrets" {
  source = "./secrets"
  secrets = {
    "EPB_API_URL" : "https://${module.register_api_application.internal_alb_name}.${var.domain_name}:443"
    "EPB_AUTH_SERVER" : "https://${module.auth_application.internal_alb_name}.${var.domain_name}:443/auth"
    "EPB_DATA_FRONTEND_DELIVERY_SNS_ARN" : var.environment != "prod" ? module.data_frontend_delivery[0].sns_topic_arn : "test",
    "EPB_DATA_FRONTEND_SESSION_SECRET" : random_string.epb_data_frontend_session_secret.result
    "EPB_DATA_WAREHOUSE_API_URL" : "https://${module.warehouse_api_application.internal_alb_name}.${var.domain_name}"
    "EPB_DATA_WAREHOUSE_QUEUES_URI" : module.warehouse_redis.redis_uri
    "EPB_UNLEASH_URI" : "https://${module.toggles_application.internal_alb_name}.${var.domain_name}:443/api"
    "EPB_QUEUES_URI" : module.warehouse_redis.redis_uri
    "ONELOGIN_CLIENT_ID" : var.environment != "prod" ? var.parameters["ONELOGIN_CLIENT_ID"] : "test"
    "ONELOGIN_HOST_URL" : var.environment != "prod" ? var.parameters["ONELOGIN_HOST_URL"] : "test"
    "ONELOGIN_TLS_KEYS" : var.environment != "prod" ? jsonencode({ "kid" = module.onelogin_keys[0].key_id, "private_key" = module.onelogin_keys[0].private_key_pem, "public_key" = module.onelogin_keys[0].public_key_pem }) : "test"
    "LANDMARK_DATA_BUCKET_NAME" : module.landmark_data.bucket_name
    "ODE_BUCKET_NAME" : module.open_data_export.bucket_name
    "ODE_BUCKET_ACCESS_KEY" : module.open_data_export.s3_access_key
    "ODE_BUCKET_SECRET" : module.open_data_export.s3_secret
    "ONS_POSTCODE_BUCKET_NAME" : module.ons_postcode_data.bucket_name
    "RDS_API_V2_SERVICE_CONNECTION_STRING" : module.register_api_database_v2.rds_db_connection_string
    "RDS_API_V2_SERVICE_READER_CONNECTION_STRING" : module.register_api_database_v2.rds_db_reader_connection_string
    "RDS_API_V2_SERVICE_PASSWORD" : module.register_api_database_v2.rds_db_password
    "RDS_API_V2_SERVICE_USERNAME" : module.register_api_database_v2.rds_db_username
    "RDS_AUTH_V2_SERVICE_CONNECTION_STRING" : module.auth_database_v2.rds_db_connection_string
    "RDS_AUTH_V2_SERVICE_PASSWORD" : module.auth_database_v2.rds_db_password
    "RDS_AUTH_V2_SERVICE_USERNAME" : module.auth_database_v2.rds_db_username
    "RDS_TOGGLES_V2_CONNECTION_STRING" : module.toggles_database_v2.rds_db_connection_string
    "RDS_TOGGLES_V2_PASSWORD" : module.toggles_database_v2.rds_db_password
    "RDS_TOGGLES_V2_USERNAME" : module.toggles_database_v2.rds_db_username
    "RDS_WAREHOUSE_V2_CONNECTION_STRING" : module.warehouse_database_v2.rds_db_connection_string
    "RDS_WAREHOUSE_V2_READER_CONNECTION_STRING" : module.warehouse_database_v2.rds_db_reader_connection_string
    "RDS_WAREHOUSE_V2_PASSWORD" : module.warehouse_database_v2.rds_db_password
    "RDS_WAREHOUSE_V2_USERNAME" : module.warehouse_database_v2.rds_db_username
    "UD_BUCKET_NAME" : module.user_data.bucket_name
    "WAREHOUSE_EXPORT_BUCKET_NAME" : module.warehouse_document_export.bucket_name
    "WAREHOUSE_EXPORT_BUCKET_ACCESS_KEY" : module.warehouse_document_export.s3_access_key
    "WAREHOUSE_EXPORT_BUCKET_SECRET" : module.warehouse_document_export.s3_secret
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
    EPB_TEAM_SLACK_URL : {
      type  = "SecureString"
      value = var.parameters["EPB_TEAM_SLACK_URL"]
    }
    EPB_TEAM_MAIN_SLACK_URL : {
      type  = "SecureString"
      value = var.parameters["EPB_TEAM_MAIN_SLACK_URL"]
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
    "NOTIFY_CLIENT_API_KEY" : {
      type  = "String"
      value = var.parameters["NOTIFY_CLIENT_API_KEY"]
    }
    "NOTIFY_EMAIL_RECIPIENT" : {
      type  = "String"
      value = var.parameters["NOTIFY_EMAIL_RECIPIENT"]
    }
    "NOTIFY_TEMPLATE_ID" : {
      type  = "String"
      value = var.parameters["NOTIFY_TEMPLATE_ID"]
    }
    "NOTIFY_DATA_API_KEY" : {
      type  = "String"
      value = var.parameters["NOTIFY_DATA_API_KEY"]
    }
    "NOTIFY_DATA_EMAIL_RECIPIENT" : {
      type  = "String"
      value = var.parameters["NOTIFY_DATA_EMAIL_RECIPIENT"]
    }
    "NOTIFY_DATA_DOWNLOAD_TEMPLATE_ID" : {
      type  = "String"
      value = var.parameters["NOTIFY_DATA_TEMPLATE_ID"]
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
    "SENTRY_DSN_DATA_FRONTEND" : {
      type  = "SecureString"
      value = var.parameters["SENTRY_DSN_DATA_FRONTEND"]
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

module "toggles_database_v2" {
  source = "./rds"

  db_name               = "unleash"
  instance_class        = var.environment == "intg" ? "db.t3.micro" : "db.m5.large"
  parameter_group_name  = module.parameter_groups.rds_pg_param_group_name
  prefix                = "${local.prefix}-toggles"
  postgres_version      = var.postgres_rds_version
  security_group_ids    = [module.toggles_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1
  storage_size          = 5
  subnet_group_name     = local.db_subnet
  vpc_id                = module.networking.vpc_id
  multi_az              = var.environment == "prod" ? true : false
  name_suffix           = "v2"
  kms_key_id            = module.rds_kms_key.key_arn
}

module "toggles_application" {
  source                = "./application"
  ci_account_id         = var.ci_account_id
  prefix                = "${local.prefix}-toggles"
  region                = var.region
  container_port        = 4242
  egress_ports          = [80, 443, 5432, var.parameters["LOGSTASH_PORT"]]
  environment_variables = {}
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_TOGGLES_V2_CONNECTION_STRING"],
  }
  parameters                                 = module.parameter_store.parameter_arns
  vpc_id                                     = module.networking.vpc_id
  fluentbit_ecr_url                          = module.fluentbit_ecr.ecr_url
  private_subnet_ids                         = module.networking.private_subnet_ids
  health_check_path                          = "/health"
  additional_task_execution_role_policy_arns = { "RDS_access" : module.toggles_database_v2.rds_full_access_policy_arn }
  aws_cloudwatch_log_group_id                = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name              = module.logging.cloudwatch_log_group_name
  logs_bucket_name                           = module.logging.logs_bucket_name
  logs_bucket_url                            = module.logging.logs_bucket_url
  internal_alb_config = {
    ssl_certificate_arn = module.ssl_certificate.certificate_arn
  }
  front_door_config = {
    ssl_certificate_arn          = module.ssl_certificate.certificate_arn
    cdn_certificate_arn          = module.cdn_certificate.certificate_arn
    cdn_allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods           = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl                = 0
    cdn_aliases                  = toset(["toggles.${var.domain_name}"])
    waf_acl_arn                  = module.waf.waf_acl_arn
    public_subnet_ids            = module.networking.public_subnet_ids
    path_based_routing_overrides = []
    extra_lb_target_groups       = 0
  }
  fargate_weighting         = var.environment == "prod" ? { standard : 10, spot : 0 } : { standard : 0, spot : 10 }
  has_target_tracking       = false
  cloudwatch_ecs_events_arn = module.logging.cloudwatch_ecs_events_arn
}

module "auth_application" {
  source                = "./application"
  ci_account_id         = var.ci_account_id
  prefix                = "${local.prefix}-auth"
  region                = var.region
  container_port        = 3001
  egress_ports          = [80, 443, 5432, var.parameters["LOGSTASH_PORT"]]
  environment_variables = {}
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_AUTH_V2_SERVICE_CONNECTION_STRING"],
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
  additional_task_execution_role_policy_arns = { "RDS_access" : module.auth_database_v2.rds_full_access_policy_arn }
  aws_cloudwatch_log_group_id                = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name              = module.logging.cloudwatch_log_group_name
  logs_bucket_name                           = module.logging.logs_bucket_name
  logs_bucket_url                            = module.logging.logs_bucket_url
  internal_alb_config = {
    ssl_certificate_arn = module.ssl_certificate.certificate_arn
  }
  front_door_config = {
    ssl_certificate_arn          = module.ssl_certificate.certificate_arn
    cdn_certificate_arn          = module.cdn_certificate.certificate_arn
    cdn_allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods           = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl                = 0
    cdn_aliases                  = toset(["auth.${var.domain_name}"])
    waf_acl_arn                  = module.waf.waf_acl_arn
    public_subnet_ids            = module.networking.public_subnet_ids
    path_based_routing_overrides = []
    extra_lb_target_groups       = 1
  }
  fargate_weighting         = var.environment == "prod" ? { standard : 10, spot : 0 } : { standard : 0, spot : 10 }
  has_target_tracking       = false
  cloudwatch_ecs_events_arn = module.logging.cloudwatch_ecs_events_arn
}

module "auth_database_v2" {
  source = "./rds"

  db_name               = "epb"
  instance_class        = var.environment == "intg" ? "db.t3.micro" : "db.m5.large"
  parameter_group_name  = module.parameter_groups.rds_pg_param_group_name
  postgres_version      = var.postgres_rds_version
  prefix                = "${local.prefix}-auth"
  security_group_ids    = [module.auth_application.ecs_security_group_id, module.bastion.security_group_id]
  storage_backup_period = 1 # to prevent weird behaviour when the backup window is set to 0
  storage_size          = 5
  subnet_group_name     = local.db_subnet
  vpc_id                = module.networking.vpc_id
  multi_az              = var.environment == "prod" ? true : false
  name_suffix           = "v2"
  kms_key_id            = module.rds_kms_key.key_arn
}

module "register_api_application" {
  source                = "./application"
  ci_account_id         = var.ci_account_id
  prefix                = "${local.prefix}-reg-api"
  region                = var.region
  container_port        = 3001
  egress_ports          = [80, 443, 5432, local.redis_port, var.parameters["LOGSTASH_PORT"]]
  environment_variables = {}
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_API_V2_SERVICE_CONNECTION_STRING"],
    "DATABASE_READER_URL" : module.secrets.secret_arns["RDS_API_V2_SERVICE_READER_CONNECTION_STRING"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"],
    "EPB_DATA_WAREHOUSE_QUEUES_URI" : module.secrets.secret_arns["EPB_DATA_WAREHOUSE_QUEUES_URI"]
  }
  parameters = merge(module.parameter_store.parameter_arns, {
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_REGISTER_API"]
  })
  has_exec_cmd_task                  = true
  deployment_minimum_healthy_percent = var.environment == "prod" ? 100 : 0
  vpc_id                             = module.networking.vpc_id
  fluentbit_ecr_url                  = module.fluentbit_ecr.ecr_url
  private_subnet_ids                 = module.networking.private_subnet_ids
  health_check_path                  = "/healthcheck"
  additional_task_execution_role_policy_arns = {
    "RDS_access" : module.register_api_database_v2.rds_full_access_policy_arn,
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
    ssl_certificate_arn = module.ssl_certificate.certificate_arn
    cdn_certificate_arn = module.cdn_certificate.certificate_arn
    cdn_allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods  = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl       = 0
    cdn_aliases         = toset(["api.${var.domain_name}"])
    waf_acl_arn         = module.waf.waf_acl_arn
    public_subnet_ids   = module.networking.public_subnet_ids
    path_based_routing_overrides = [
      # forward requests for auth tokens to the auth application
      {
        path_pattern     = ["/auth/*"]
        target_group_arn = module.auth_application.front_door_alb_extra_target_group_arns[0]
      }
    ]
    extra_lb_target_groups = 0
  }
  task_max_capacity         = var.task_max_capacity
  task_desired_capacity     = var.task_desired_capacity
  task_min_capacity         = var.task_min_capacity
  task_cpu                  = var.task_cpu
  task_memory               = var.task_memory
  fargate_weighting         = var.environment == "prod" ? { standard : 10, spot : 0 } : { standard : 0, spot : 10 }
  cloudwatch_ecs_events_arn = module.logging.cloudwatch_ecs_events_arn
}

module "register_api_database_v2" {
  source = "./aurora_rds"

  cluster_parameter_group_name  = module.parameter_groups.aurora_pg_param_group_name
  db_name                       = "epb"
  instance_class                = var.environment == "intg" ? "db.t3.medium" : var.environment == "stag" ? "db.r5.large" : "db.r5.2xlarge"
  instance_parameter_group_name = module.parameter_groups.rds_pg_param_group_name
  prefix                        = "${local.prefix}-reg-api"
  postgres_version              = var.postgres_aurora_version
  security_group_ids            = [module.register_api_application.ecs_security_group_id, module.bastion.security_group_id, module.scheduled_tasks_application.ecs_security_group_id]
  storage_backup_period         = var.storage_backup_period
  subnet_group_name             = local.db_subnet
  vpc_id                        = module.networking.vpc_id
  name_suffix                   = "v2"
  kms_key_id                    = module.rds_kms_key.key_arn
}

module "scheduled_tasks_application" {
  source = "./application"

  address_base_updater_ecr = module.address_base_updater_ecr.ecr_url
  additional_task_execution_role_policy_arns = {
    "RDS_access" : module.register_api_database_v2.rds_full_access_policy_arn,
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  additional_task_role_policy_arns = {
    "LandmarkData_S3_access" : module.landmark_data.s3_read_access_policy_arn,
    "OnsPostcodeData_S3_access" : module.ons_postcode_data.s3_read_access_policy_arn,
    "OpenDataExport_S3_access" : module.open_data_export.s3_write_access_policy_arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  ci_account_id                 = var.ci_account_id
  container_port                = 80
  egress_ports                  = [80, 443, 5432, local.redis_port, var.parameters["LOGSTASH_PORT"]]
  enable_execute_command        = true
  environment_variables         = {}
  exec_cmd_task_cpu             = var.environment == "intg" ? 512 : 1024
  exec_cmd_task_ram             = var.environment == "intg" ? 2048 : 8192
  external_ecr                  = module.register_api_application.ecr_repository_url
  fluentbit_ecr_url             = module.fluentbit_ecr.ecr_url
  has_start_task                = false
  has_exec_cmd_task             = true
  has_target_tracking           = false
  health_check_path             = "/healthcheck"
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  parameters = merge(module.parameter_store.parameter_arns, {
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_REGISTER_WORKER"]
  })
  prefix             = "${local.prefix}-scheduled-tasks"
  private_subnet_ids = module.networking.private_subnet_ids
  region             = var.region
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_API_V2_SERVICE_CONNECTION_STRING"],
    "DATABASE_READER_URL" : module.secrets.secret_arns["RDS_API_V2_SERVICE_READER_CONNECTION_STRING"],
    "EPB_DATA_WAREHOUSE_QUEUES_URI" : module.secrets.secret_arns["EPB_DATA_WAREHOUSE_QUEUES_URI"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"],
    "LANDMARK_DATA_BUCKET_NAME" : module.secrets.secret_arns["LANDMARK_DATA_BUCKET_NAME"],
    "ODE_BUCKET_NAME" : module.secrets.secret_arns["ODE_BUCKET_NAME"],
    "ONS_POSTCODE_BUCKET_NAME" : module.secrets.secret_arns["ONS_POSTCODE_BUCKET_NAME"]
  }
  task_desired_capacity     = 0
  task_max_capacity         = 3
  task_min_capacity         = 0
  vpc_id                    = module.networking.vpc_id
  cloudwatch_ecs_events_arn = module.logging.cloudwatch_ecs_events_arn
}

module "warehouse_scheduled_tasks_application" {
  source                = "./application"
  ci_account_id         = var.ci_account_id
  has_start_task        = false
  has_exec_cmd_task     = true
  prefix                = "${local.prefix}-warehouse-scheduled-tasks"
  region                = var.region
  container_port        = 80
  egress_ports          = [80, 443, 5432, var.parameters["LOGSTASH_PORT"]]
  environment_variables = {}
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_WAREHOUSE_V2_CONNECTION_STRING"],
    "UD_BUCKET_NAME" : module.secrets.secret_arns["UD_BUCKET_NAME"],
  }
  parameters = merge(module.parameter_store.parameter_arns, {
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_DATA_WAREHOUSE"]
  })
  vpc_id             = module.networking.vpc_id
  fluentbit_ecr_url  = module.fluentbit_ecr.ecr_url
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = "/healthcheck"
  additional_task_execution_role_policy_arns = {
    "RDS_access" : module.warehouse_database_v2.rds_full_access_policy_arn,
  }
  additional_task_role_policy_arns = {
    "UserData_S3_access" : module.user_data.s3_write_access_policy_arn
  }

  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  enable_execute_command        = true
  task_max_capacity             = 3
  task_desired_capacity         = 0
  task_min_capacity             = 0
  external_ecr                  = module.warehouse_application.ecr_repository_url
  has_target_tracking           = false
  cloudwatch_ecs_events_arn     = module.logging.cloudwatch_ecs_events_arn
}

module "frontend_application" {
  source                             = "./application"
  ci_account_id                      = var.ci_account_id
  prefix                             = "${local.prefix}-frontend"
  region                             = var.region
  container_port                     = 3001
  deployment_minimum_healthy_percent = var.environment == "intg" ? 0 : 100
  egress_ports                       = [80, 443, 5432, var.parameters["LOGSTASH_PORT"]]
  environment_variables = {
    "EPB_SUSPECTED_BOT_USER_AGENTS" : var.suspected_bot_user_agents,
    "GTM_PROPERTY_FINDING" : var.gtm_property_finding,
    "GTM_PROPERTY_GETTING" : var.gtm_property_getting,
    "EPB_RECAPTCHA_SITE_KEY" : var.recaptcha_site_key,
    "EPB_RECAPTCHA_SITE_SECRET" : var.recaptcha_secret_key
  }
  secrets = {
    "EPB_API_URL" : module.secrets.secret_arns["EPB_API_URL"],
    "EPB_AUTH_SERVER" : module.secrets.secret_arns["EPB_AUTH_SERVER"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"]
    "EPB_DATA_WAREHOUSE_API_URL" : module.secrets.secret_arns["EPB_DATA_WAREHOUSE_API_URL"]
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
    waf_acl_arn                    = module.waf.waf_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
    path_based_routing_overrides   = []
    extra_lb_target_groups         = 0
    cdn_cache_cookie_behaviour     = "whitelist"
    cdn_cache_cookie_items         = ["cookie_consent"]
    cdn_include_static_error_pages = true
    error_pages_bucket_name        = module.error_pages.error_pages_bucket_name
  }
  task_max_capacity                = var.task_max_capacity
  task_desired_capacity            = var.task_desired_capacity
  task_min_capacity                = var.task_min_capacity
  task_cpu                         = var.task_cpu
  task_memory                      = var.task_memory
  enable_execute_command           = var.environment != "prod"
  fargate_weighting                = var.environment == "prod" ? { standard : 10, spot : 0 } : { standard : 0, spot : 10 }
  cloudwatch_ecs_events_arn        = module.logging.cloudwatch_ecs_events_arn
  is_fluentbit_container_essential = var.environment == "intg" ? true : false
}

module "data_frontend_application" {
  count                              = var.environment == "prod" ? 0 : 1
  source                             = "./application"
  ci_account_id                      = var.ci_account_id
  prefix                             = "${local.prefix}-data-frontend"
  region                             = var.region
  container_port                     = 3001
  deployment_minimum_healthy_percent = var.environment == "intg" ? 0 : 100
  egress_ports                       = [80, 443, 5432, var.parameters["LOGSTASH_PORT"]]
  environment_variables = {
    "AWS_S3_USER_DATA_BUCKET_NAME" : module.user_data.bucket_name
  }
  secrets = {
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"]
    "SEND_DOWNLOAD_TOPIC_ARN" : module.secrets.secret_arns["EPB_DATA_FRONTEND_DELIVERY_SNS_ARN"]
    "SESSION_SECRET" : module.secrets.secret_arns["EPB_DATA_FRONTEND_SESSION_SECRET"]
    "EPB_AUTH_SERVER" : module.secrets.secret_arns["EPB_AUTH_SERVER"],
    "EPB_DATA_WAREHOUSE_API_URL" : module.secrets.secret_arns["EPB_DATA_WAREHOUSE_API_URL"]
    "ONELOGIN_CLIENT_ID" : module.secrets.secret_arns["ONELOGIN_CLIENT_ID"]
    "ONELOGIN_HOST_URL" : module.secrets.secret_arns["ONELOGIN_HOST_URL"]
    "ONELOGIN_TLS_KEYS" : module.secrets.secret_arns["ONELOGIN_TLS_KEYS"]
  }
  parameters = merge(module.parameter_store.parameter_arns, {
    "EPB_AUTH_CLIENT_ID" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_ID"],
    "EPB_AUTH_CLIENT_SECRET" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_SECRET"]
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_DATA_FRONTEND"]
  })
  vpc_id                                     = module.networking.vpc_id
  fluentbit_ecr_url                          = module.fluentbit_ecr.ecr_url
  private_subnet_ids                         = module.networking.private_subnet_ids
  health_check_path                          = "/healthcheck"
  additional_task_execution_role_policy_arns = {}
  additional_task_role_policy_arns = {
    "DataFrontendDelivery_SNS_access" : module.data_frontend_delivery[0].sns_write_access_policy_arn,
    "UseData_S3_access" : module.user_data.s3_read_access_policy_arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  front_door_config = {
    ssl_certificate_arn = module.ssl_certificate.certificate_arn
    cdn_certificate_arn = module.cdn_certificate.certificate_arn
    cdn_allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cdn_cached_methods  = ["GET", "HEAD", "OPTIONS"]
    cdn_cache_ttl       = 60 # 1 minute
    cdn_aliases = toset([
      var.data_service_url,
    ])
    waf_acl_arn                    = module.waf.waf_acl_arn
    public_subnet_ids              = module.networking.public_subnet_ids
    path_based_routing_overrides   = []
    extra_lb_target_groups         = 0
    cdn_cache_cookie_behaviour     = "whitelist"
    cdn_cache_cookie_items         = ["cookie_consent", "epb_data.session", "state", "nonce"]
    cdn_include_static_error_pages = true
    error_pages_bucket_name        = module.error_pages.error_pages_bucket_name
  }
  task_max_capacity                = var.task_max_capacity
  task_desired_capacity            = var.task_desired_capacity
  task_min_capacity                = var.task_min_capacity
  task_cpu                         = var.task_cpu
  task_memory                      = var.task_memory
  enable_execute_command           = var.environment != "prod"
  fargate_weighting                = var.environment == "prod" ? { standard : 10, spot : 0 } : { standard : 0, spot : 10 }
  cloudwatch_ecs_events_arn        = module.logging.cloudwatch_ecs_events_arn
  is_fluentbit_container_essential = var.environment == "intg" ? true : false
}

module "warehouse_application" {
  source                = "./application"
  ci_account_id         = var.ci_account_id
  prefix                = "${local.prefix}-warehouse"
  region                = var.region
  container_port        = 80
  egress_ports          = [80, 443, 5432, local.redis_port, var.parameters["LOGSTASH_PORT"]]
  environment_variables = {}
  has_exec_cmd_task     = true
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_WAREHOUSE_V2_CONNECTION_STRING"],
    "EPB_API_URL" : module.secrets.secret_arns["EPB_API_URL"],
    "EPB_AUTH_SERVER" : module.secrets.secret_arns["EPB_AUTH_SERVER"],
    "EPB_QUEUES_URI" : module.secrets.secret_arns["EPB_QUEUES_URI"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"]
  }
  parameters = merge(module.parameter_store.parameter_arns, {
    "EPB_AUTH_CLIENT_ID" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_ID"],
    "EPB_AUTH_CLIENT_SECRET" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_SECRET"]
    "SENTRY_DSN" : module.parameter_store.parameter_arns["SENTRY_DSN_DATA_WAREHOUSE"]
    "NOTIFY_CLIENT_API_KEY" : module.parameter_store.parameter_arns["NOTIFY_CLIENT_API_KEY"]
    "NOTIFY_EMAIL_RECIPIENT" : module.parameter_store.parameter_arns["NOTIFY_EMAIL_RECIPIENT"]
    "NOTIFY_TEMPLATE_ID" : module.parameter_store.parameter_arns["NOTIFY_TEMPLATE_ID"]
  })
  vpc_id             = module.networking.vpc_id
  fluentbit_ecr_url  = module.fluentbit_ecr.ecr_url
  private_subnet_ids = module.networking.private_subnet_ids
  health_check_path  = null
  additional_task_role_policy_arns = {
    "WarehouseDocumentExport_S3_access" : module.warehouse_document_export.s3_write_access_policy_arn
  }
  additional_task_execution_role_policy_arns = {
    "RDS_access" : module.warehouse_database_v2.rds_full_access_policy_arn
    "Redis_access" : data.aws_iam_policy.elasticache_full_access.arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  enable_execute_command        = true
  fargate_weighting             = { standard : 0, spot : 10 }
  has_target_tracking           = false
  cloudwatch_ecs_events_arn     = module.logging.cloudwatch_ecs_events_arn
}

module "warehouse_api_application" {
  source                = "./application"
  ci_account_id         = var.ci_account_id
  prefix                = "${local.prefix}-warehouse-api"
  region                = var.region
  container_port        = 3001
  egress_ports          = [80, 443, 5432, var.parameters["LOGSTASH_PORT"]]
  environment_variables = {}
  secrets = {
    "DATABASE_URL" : module.secrets.secret_arns["RDS_WAREHOUSE_V2_READER_CONNECTION_STRING"],
    "EPB_AUTH_CLIENT_ID" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_ID"],
    "EPB_AUTH_CLIENT_SECRET" : module.parameter_store.parameter_arns["WAREHOUSE_EPB_AUTH_CLIENT_SECRET"]
    "EPB_AUTH_SERVER" : module.secrets.secret_arns["EPB_AUTH_SERVER"],
    "EPB_UNLEASH_URI" : module.secrets.secret_arns["EPB_UNLEASH_URI"]
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
    "RDS_access" : module.warehouse_database_v2.rds_full_access_policy_arn
  }
  aws_cloudwatch_log_group_id   = module.logging.cloudwatch_log_group_id
  aws_cloudwatch_log_group_name = module.logging.cloudwatch_log_group_name
  logs_bucket_name              = module.logging.logs_bucket_name
  logs_bucket_url               = module.logging.logs_bucket_url
  enable_execute_command        = true
  has_target_tracking           = false
  internal_alb_config = {
    ssl_certificate_arn = module.ssl_certificate.certificate_arn
  }
  task_max_capacity         = var.task_max_capacity
  task_desired_capacity     = var.task_desired_capacity
  task_min_capacity         = var.task_min_capacity
  task_cpu                  = var.task_cpu
  task_memory               = var.task_memory
  fargate_weighting         = var.environment == "prod" ? { standard : 10, spot : 0 } : { standard : 0, spot : 10 }
  cloudwatch_ecs_events_arn = module.logging.cloudwatch_ecs_events_arn
}


module "warehouse_database_v2" {
  source = "./aurora_rds"

  cluster_parameter_group_name  = module.parameter_groups.aurora_pg_17_serverless_param_group_name
  db_name                       = "epb"
  instance_class                = "db.serverless"
  instance_parameter_group_name = module.parameter_groups.aurora_pg_param_group_name
  postgres_version              = var.data_warehouse_postgres_aurora_version
  prefix                        = "${local.prefix}-warehouse"
  security_group_ids            = local.dwh_security_groups
  storage_backup_period         = var.storage_backup_period
  subnet_group_name             = local.db_subnet
  vpc_id                        = module.networking.vpc_id
  scaling_configuration         = var.environment == "prod" ? { max_capacity = 64, min_capacity = 2 } : { max_capacity = 16, min_capacity = 0.5 }
  name_suffix                   = "v2"
  kms_key_id                    = module.rds_kms_key.key_arn
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
    "API" : module.register_api_database_v2.rds_full_access_policy_arn
    "Auth" : module.auth_database_v2.rds_full_access_policy_arn
    "Toggles" : module.toggles_database_v2.rds_full_access_policy_arn
    "Warehouse" : module.warehouse_database_v2.rds_full_access_policy_arn
  }
}

# logging and alerts

module "logging" {
  source                    = "./logging"
  prefix                    = local.prefix
  region                    = var.region
  is_cloudwatch_insights_on = 1
  memory_size               = var.environment == "prod" ? 256 : 128
}

module "fluentbit_ecr" {
  source              = "./ecr"
  ecr_repository_name = "${local.prefix}-fluentbit"
}

module "alerts" {
  source = "./alerts"

  prefix                     = local.prefix
  region                     = var.region
  environment                = var.parameters["STAGE"]
  slack_webhook_url          = var.parameters["EPB_TEAM_SLACK_URL"]
  main_slack_alerts          = var.environment == "intg" ? 1 : 0
  main_slack_webhook_url     = var.parameters["EPB_TEAM_MAIN_SLACK_URL"]
  cloudtrail_log_group_name  = module.logging.cloudtrail_log_group_name
  cloudwatch_ecs_events_name = module.logging.cloudwatch_ecs_events_name

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
    warehouse = {
      cluster_name = module.warehouse_application.ecs_cluster_name
      service_name = module.warehouse_application.ecs_service_name
    },
    warehouse_api = {
      cluster_name = module.warehouse_api_application.ecs_cluster_name
      service_name = module.warehouse_api_application.ecs_service_name
    }
  }

  exec_cmd_tasks = {
    auth_service          = module.auth_application.ecs_exec_cmd_task_family
    reg_api_service       = module.register_api_application.ecs_exec_cmd_task_family
    scheduled_tasks       = module.scheduled_tasks_application.ecs_exec_cmd_task_family
    warehouse_service     = module.warehouse_application.ecs_exec_cmd_task_family
    warehouse_api_service = module.warehouse_api_application.ecs_exec_cmd_task_family
  }

  rds_instances = {
    auth_service = module.auth_database_v2.rds_instance_identifier
    toggles      = module.toggles_database_v2.rds_instance_identifier
  }

  rds_clusters = {
    warehouse      = module.warehouse_database_v2.rds_cluster_identifier
    api_service_v2 = module.register_api_database_v2.rds_cluster_identifier
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

module "open_data_export" {
  source = "./s3_bucket_data_export"
  prefix = "${local.prefix}-open-data-export"
}

module "warehouse_document_export" {
  source = "./s3_bucket_data_export"
  prefix = "${local.prefix}-warehouse-document-export"
}

module "ons_postcode_data" {
  source = "./s3_bucket"
  prefix = "${local.prefix}-ons-postcode-data"
}

module "landmark_data" {
  source = "./s3_bucket"
  prefix = "${local.prefix}-landmark-data"
}

module "user_data" {
  source           = "./s3_bucket"
  prefix           = "${local.prefix}-user-data"
  lifecycle_prefix = "/output"
  expiration_days  = 7
}

module "parameter_groups" {
  source = "./database_parameter_groups"
}

locals {
  register_origins = ["https://${var.get_service_url}", "https://${var.find_service_url}"]
  allowed_origins  = var.environment == "prod" ? local.register_origins : concat(local.register_origins, ["https://${var.data_service_url}"])
}

module "error_pages" {
  source          = "./error_pages"
  prefix          = "${local.prefix}-error-pages"
  oai_iam_arn     = module.frontend_application.oai_iam_arn
  allowed_origins = local.allowed_origins
}

module "legacy_domain_redirect" {
  source              = "./legacy_domain_redirect"
  count               = var.environment == "prod" ? 1 : 0
  cdn_certificate_arn = module.cdn_certificate.certificate_arn
  waf_acl_arn         = module.waf.waf_acl_arn
}

module "dashboard" {
  source      = "./dashboard"
  environment = var.environment
  region      = var.region
  albs = {
    auth             = module.auth_application.front_door_alb_arn_suffix
    auth_internal    = module.auth_application.internal_alb_arn_suffix
    reg_api          = module.register_api_application.front_door_alb_arn_suffix
    reg_api_internal = module.register_api_application.internal_alb_arn_suffix
    toggles          = module.toggles_application.front_door_alb_arn_suffix
    toggles_internal = module.toggles_application.internal_alb_arn_suffix
    frontend         = module.frontend_application.front_door_alb_arn_suffix
  }
  target_groups = {
    reg_api          = module.register_api_application.front_door_alb_tg_arn_suffix
    reg_api_internal = module.register_api_application.internal_alb_tg_arn_suffix
    frontend         = module.frontend_application.front_door_alb_tg_arn_suffix
  }
  cloudfront_distribution_ids = {
    auth       = module.auth_application.cloudfront_distribution_ids[0]
    reg        = module.register_api_application.cloudfront_distribution_ids[0]
    toggles    = module.toggles_application.cloudfront_distribution_ids[0]
    frontend_0 = module.frontend_application.cloudfront_distribution_ids[0]
    frontend_1 = module.frontend_application.cloudfront_distribution_ids[1]
  }
}

# The "rds_export_to_s3" module code is based on:
# https://github.com/binbashar/terraform-aws-rds-export-to-s3/tree/master
module "rds_export_to_s3" {
  source                     = "./rds_export_to_s3"
  prefix                     = local.prefix
  database_names             = module.warehouse_database_v2.rds_cluster_identifier
  snapshots_bucket_name      = local.rds_snapshot_backup_bucket
  snapshots_bucket_prefix    = "rds_snapshots/"
  create_customer_kms_key    = true
  create_notifications_topic = true
  tags                       = local.rds_snapshot_backup_tags
  num_days_bucket_retention  = var.environment == "prod" ? 21 : 7
}

module "schedule_task_role" {
  source = "./scheduled_tasks/"
  prefix = local.prefix

}

module "register_schedule_tasks" {
  source = "./register_scheduled_tasks"
  app_containers = {
    register_container_name     = module.scheduled_tasks_application.migration_container_name
    register_task_arn           = module.scheduled_tasks_application.ecs_task_exec_arn
    address_base_container_name = module.scheduled_tasks_application.address_base_updater_container_name
    address_base_task_arn       = module.scheduled_tasks_application.address_base_ecs_task_exec_arn
  }
  prefix                = local.prefix
  cluster_arn           = module.scheduled_tasks_application.ecs_cluster_arn
  security_group_id     = module.scheduled_tasks_application.ecs_security_group_id
  private_db_subnet_ids = module.networking.private_db_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  event_rule_arn        = module.schedule_task_role.ecs_events_arn

}

module "warehouse_schedule_tasks" {
  source            = "./warehouse_scheduled_tasks"
  prefix            = local.prefix
  cluster_arn       = module.warehouse_scheduled_tasks_application.ecs_cluster_arn
  security_group_id = module.warehouse_scheduled_tasks_application.ecs_security_group_id
  vpc_subnet_ids    = module.networking.private_db_subnet_ids
  task_arn          = module.warehouse_scheduled_tasks_application.ecs_task_exec_arn
  container_name    = module.warehouse_scheduled_tasks_application.migration_container_name
  event_rule_arn    = module.schedule_task_role.ecs_events_arn
}

module "address_base_updater_ecr" {
  source              = "./ecr"
  ecr_repository_name = "${local.prefix}-address-base-updater-ecr"
}

module "rds_kms_key" {
  source            = "./kms"
  prefix            = local.prefix
  environment       = var.environment
  backup_account_id = var.backup_account_id
}

module "backup-vault" {
  source            = "./backup"
  prefix            = local.prefix
  backup_account_id = var.backup_account_id
  databases_to_backup_arn = [
    module.register_api_database_v2.rds_db_arn,
    module.auth_database_v2.rds_db_arn,
    module.toggles_database_v2.rds_db_arn,
    module.warehouse_database_v2.rds_db_arn
  ]
  kms_key_arn      = module.rds_kms_key.key_arn
  backup_frequency = var.environment == "prod" ? "cron(01 4 * * ? *)" : "cron(01 4 ? * wed *)"
}

module "data_warehouse_glue" {
  count                      = var.environment == "prod" ? 0 : 1
  source                     = "./glue"
  prefix                     = local.prefix
  subnet_group_id            = module.networking.private_db_subnet_first_id
  db_instance                = module.warehouse_database_v2.rds_db_reader_endpoint
  db_user                    = module.warehouse_database_v2.rds_db_username
  db_password                = module.warehouse_database_v2.rds_db_password
  subnet_group_az            = module.networking.private_db_subnet_first_az
  vpc_id                     = module.networking.vpc_id
  output_bucket_name         = module.user_data.bucket_name
  output_bucket_read_policy  = module.user_data.s3_read_access_policy_arn
  output_bucket_write_policy = module.user_data.s3_write_access_policy_arn
}