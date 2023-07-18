variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "has_db_subnet" {
  type    = number
  default = 0
}