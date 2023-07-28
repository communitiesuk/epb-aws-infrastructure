variable "vpc_cidr_block" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "storage_backup_period" {
  default = 1
  type    = number
}

variable "ci_account_id" {
  default = "145141030745"
  type    = string
}

variable "domain_name" {
  type = string
}

variable "subject_alternative_names" {
  type = list(string)
}

variable "subdomain_suffix" {
  type = string
}

variable "slack_webhook_url" {
  type      = string
  sensitive = true
}

variable "parameters" {
  description = "A map of parameter values. Keys should be a subset of the ones passed to 'parameters' module."
  type        = map(string)
  sensitive   = true
}

variable "banned_ip_addresses" {
  type = list(map(string))
}

variable "pass_vpc_cidr" {
  type        = string
  default = ""
}

variable "vpc_peering_connection_id" {
  type        = string
  default = ""
}