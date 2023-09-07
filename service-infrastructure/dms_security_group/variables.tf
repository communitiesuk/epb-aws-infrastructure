variable "name" {
  type = string
}

variable "prefix" {
  type    = string
  default = "epb-prod-dms"
}

variable "tag" {
  type    = string
  default = "epb-dms-security-group"
}


variable "pass_vpc_cidr" {
  type    = list(string)
  default = []
}

variable "vpc_id" {
  type = string
}
