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

variable "instance_class" {
  type = string
}

variable "cluster_parameter_group_name" {
  type = string
}

variable "instance_parameter_group_name" {
  type = string
}

variable "postgres_version" {
  type = string
}

variable "scaling_configuration" {
  type = object({
    max_capacity = number
    min_capacity = number
  })

  default = null
}

variable "kms_key_id" {
  description = "Custom encryption key for db"
  default     = null
  type        = string
}

variable "name_suffix" {
  description = "Suffix added to the cluster name for when have 2 versions of the same db e.g v2"
  default     = null
  type        = string
}

