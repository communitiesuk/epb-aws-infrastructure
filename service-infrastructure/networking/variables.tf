variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr_block" {
  type    = string
  default = ""
}

variable "pass_vpc_cidr" {
  type    = string
  default = ""
}

variable "vpc_peering_connection_id" {
  type    = string
  default = ""
}