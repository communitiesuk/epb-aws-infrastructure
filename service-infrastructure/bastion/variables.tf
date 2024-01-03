variable "subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "rds_access_policy_arns" {
  type = map(string)
}

variable "name" {
  type    = string
  default = "bastion"
}

variable "tag" {
  type    = string
  default = "bastion-host"
}

