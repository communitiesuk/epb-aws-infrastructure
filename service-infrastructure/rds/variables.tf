variable "prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_group_name" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "db_name" {
  type = string
}

variable "storage_backup_period" {
  type = number
}

variable "storage_size" {
  type = number
}

variable "instance_class" {
  type = string
}

variable "parameter_group_name" {
  type = string
}

variable "pg_engine_version" {
  type    = string
  default = "14.10"
}

