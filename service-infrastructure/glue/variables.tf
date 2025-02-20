variable "prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_group_id" {
  type = string
}

variable "subnet_group_az" {
  type = string
}

variable "db_instance" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}

variable "secrets" {
  default = {}
  type    = map(string)
}

