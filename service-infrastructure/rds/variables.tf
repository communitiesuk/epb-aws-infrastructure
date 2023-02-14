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

variable "engine" {
  type = string
  validation {
    condition     = contains(["postgres", "aurora-postgresql"], var.engine)
    error_message = "Engine must be either postgres or aurora-postgresql"
  }
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