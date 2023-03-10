variable "environment" {
  default = "intg"
  type    = string
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
  default = "centraldatastore.net"
  type    = string
}

variable "subdomain_suffix" {
  default = "-integration"
  type    = string
}
