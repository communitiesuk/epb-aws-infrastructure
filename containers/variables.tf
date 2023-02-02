variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "container_port" {
  type = number
}

variable "container_image" {
  type = string
}

variable "environment_variables" {
  type = list(map(string))
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "health_check_path" {
  type = string
}

variable "vpc_id" {
  type = string
}