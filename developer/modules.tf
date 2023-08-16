module "ci_role" {
  source        = "./access"
  ci_account_id = var.ci_account_id
}

module "prototypes" {
  source     = "./protoypes"
  ci_role_id = module.ci_role.ci_role_id
}

module "tech_docs" {
  source                 = "./tech-docs"
  ci_account_id          = var.ci_account_id
  ci_role_id             = module.ci_role.ci_role_id
  login_credentials_hash = var.login_credentials_hash
  domain_name            = var.domain_name
}