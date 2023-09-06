module "ci_role" {
  source        = "./access"
  ci_account_id = var.ci_account_id
}

module "parameters" {
  source = "./parameter_store"
  parameters = {
    "PROTOTYPES_USERNAME" : {
      type  = "String"
      value = var.parameters["PROTOTYPES_USERNAME"]
    }
    "PROTOTYPES_PASSWORD" : {
      type  = "String"
      value = var.parameters["PROTOTYPES_PASSWORD"]
    }

  }
}

module "prototypes" {
  source     = "./prototypes"
  ci_role_id = module.ci_role.ci_role_id
  environment_variables = {
    "USERNAME" : module.parameters.parameter_arns["PROTOTYPES_USERNAME"],
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
