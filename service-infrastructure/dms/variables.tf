variable "subnet_group_ids" {
  type = list(string)
}

variable "name" {
  type    = string
  default = "epb-dms"
}

variable "vpc_id" {
  type = string
}

variable "tag" {
  type    = string
  default = "epb-dms-security-group"
}

variable "pass_vpc_cidr" {
  type    = list(string)
  default = []
}

variable "target_db_name" {
  type = string

}

variable "rds_access_policy_arns" {
  type = map(string)
}

variable "secrets" {
  type = map(string)
}