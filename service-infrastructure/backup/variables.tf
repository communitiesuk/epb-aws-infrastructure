variable "kms_key_arn" {
  type = string
}

variable "backup_account_id" {
  type = string
}

variable "backup_account_vault_name" {
  default = "backup_vault"
  type    = string
}

variable "databases_to_backup_arn" {
  type = list(string)
}

variable "backup_frequency" {
  type = string
}

variable "prefix" {
  type = string
}
