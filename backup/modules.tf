module "rds_kms_key" {
  source      = "./kms"
  account_ids = var.account_ids
}

module "backup_vault" {
  source      = "./backup"
  kms_key_arn = module.rds_kms_key.key_arn
  account_ids = var.account_ids
}