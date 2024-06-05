variable "subnet_group_ids" {
  type = list(string)
}

variable "name" {
  type = string
}

variable "prefix" {
  type = string
}

variable "target_db_name" {
  type = string
}

variable "source_db_name" {
  type = string
}

variable "rds_access_policy_arns" {
  type = map(string)
}

variable "secrets" {
  type = map(string)
}

variable "mapping_file" {
  type = string
}

variable "settings_file" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "security_group_id" {
  type = string
}