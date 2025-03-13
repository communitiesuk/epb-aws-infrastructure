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

variable "parameters" {
  description = "A map of parameter values. Keys should be a subset of the ones passed to 'parameters' module."
  type        = map(string)
  sensitive   = true
}

variable "banned_ip_addresses" {
  type = list(map(string))
}

variable "banned_ipv6_addresses" {
  type = list(map(string))
}

variable "permitted_ip_addresses" {
  type = list(map(string))
}

variable "permitted_ipv6_addresses" {
  type = list(map(string))
}

variable "find_service_url" {
  type = string
}

variable "get_service_url" {
  type = string

}

variable "data_service_url" {
  type    = string
  default = null
}

variable "task_desired_capacity" {
  type    = number
  default = 2
}

variable "task_min_capacity" {
  type    = number
  default = 2
}

variable "task_max_capacity" {
  type    = number
  default = 4
}

variable "task_cpu" {
  type    = number
  default = 512
}

variable "task_memory" {
  type    = number
  default = 2048
}

variable "suspected_bot_user_agents" {
  type    = string
  default = "[]"
}

variable "gtm_property_finding" {
  type    = string
  default = ""
}

variable "gtm_property_getting" {
  type    = string
  default = ""
}

variable "recaptcha_site_key" {
  type    = string
  default = ""
}

variable "recaptcha_secret_key" {
  type    = string
  default = ""
}

variable "postgres_rds_version" {
  type    = string
  default = "14.13"
}

variable "postgres_aurora_version" {
  type    = string
  default = "14.12"
}
