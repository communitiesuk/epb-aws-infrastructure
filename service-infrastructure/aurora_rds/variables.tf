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


