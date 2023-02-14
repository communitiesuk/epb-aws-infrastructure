variable "environment" {
  default = "intg"
  type    = string
}

variable "region" {
  default = "eu-west-2"
  type    = string
}

variable "storage_backup_period" {
  default = 0
  type    = number
}