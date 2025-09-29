module "ci_role" {
  source        = "./access"
  ci_account_id = var.ci_account_id
}

module "parameters" {
  source = "./parameter_store"
  parameters = {
    "PROTOTYPES_PASSWORD" : {
      type  = "String"
      value = var.parameters["PROTOTYPES_PASSWORD"]
    }
    EPB_TEAM_MAIN_SLACK_URL : {
      type  = "SecureString"
      value = var.parameters["EPB_TEAM_MAIN_SLACK_URL"]
    }
  }
}

module "secrets" {
  source = "./secrets"

  secrets = {
    "SCOTLAND_BUCKET_NAME" : module.scotland_data.bucket_name
    "SCOTLAND_BUCKET_ACCESS_KEY" : module.scotland_data.s3_access_key
    "SCOTLAND_BUCKET_SECRET" : module.scotland_data.s3_secret
    "SCOTLAND_BUCKET_READONLY_ACCESS_KEY" : module.scotland_data.s3_readonly_access_key
    "SCOTLAND_BUCKET_READONLY_SECRET" : module.scotland_data.s3_readonly_secret
  }
}

module "prototypes" {
  source     = "./prototypes"
  ci_role_id = module.ci_role.ci_role_id
  environment_variables = {
    "PASSWORD" : module.parameters.parameter_arns["PROTOTYPES_PASSWORD"],
  }
  domain_name = var.domain_name
}

module "tech_docs" {
  source                 = "./tech-docs"
  ci_account_id          = var.ci_account_id
  ci_role_id             = module.ci_role.ci_role_id
  login_credentials_hash = var.login_credentials_hash
  domain_name            = var.domain_name
}

module "api-docs" {
  source        = "./api-docs"
  ci_account_id = var.ci_account_id
  domain_name   = var.domain_name
  ci_role_id    = module.ci_role.ci_role_id
}

module "logging" {
  source = "./logging"
  region = var.region
}

module "alerts" {
  source = "./alerts"

  region                    = var.region
  environment               = "developer"
  main_slack_webhook_url    = var.parameters["EPB_TEAM_MAIN_SLACK_URL"]
  cloudtrail_log_group_name = module.logging.cloudtrail_log_group_name
}

module "scotland_data" {
  source      = "./s3_bucket_data_export"
  bucket_name = "scotland-data"
  allow_write = true
}
