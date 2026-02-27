module "dynamodb_kms_key" {
  source            = "../kms"
  prefix            = var.prefix
  environment       = var.environment
  backup_account_id = var.backup_account_id

  description      = "KMS key for DynamoDB table encryption"
  alias_suffix     = "dynamodb-user-credentials-key"
  policy_id_suffix = "dynamodb-user-credentials"
  via_services     = ["dynamodb.${var.region}.amazonaws.com"]
}