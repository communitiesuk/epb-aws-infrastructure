variable "prefix" {
  description = "Prefix that will be used for naming resources. '<prefix>resouce-name'."
  type        = string
  default     = null
}

variable "environment" {
  type    = string
  default = null
}

variable "backup_account_id" {
  type    = string
  default = null
}

variable "description" {
  description = "Description for the KMS key."
  type        = string
}

variable "alias_suffix" {
  description = "Suffix used for the KMS alias name."
  type        = string
}

variable "via_services" {
  description = "List of AWS service principals (kms:ViaService) allowed to use this key."
  type        = list(string)
}

variable "policy_id_suffix" {
  description = "Suffix used for the key policy Id field (auto-<suffix>)."
  type        = string
}
