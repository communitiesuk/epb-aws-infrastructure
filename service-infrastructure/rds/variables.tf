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

variable "postgres_version" {
  type = string
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "kms_key_id" {
  description = "Custom encryption key for db"
  default     = null
  type        = string
}

variable "name_suffix" {
  description = "Suffix added to the instance name when we have 2 versions of the same db"
  default     = null
  type        = string
}
