variable "prefix" {
  type    = string
  default = "epb-dev-prototypes"
}

variable "cidr_block" {
  type    = string
  default = "10.1.0.0/16"
}

variable "ci_role_id" {
  type = string
}

variable "environment_variables" {
  type = map(string)
}

variable "domain_name" {
  type = string
}

variable "region" {
  type    = string
  default = "eu-west-2"
}
