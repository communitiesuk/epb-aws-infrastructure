variable "prefix" {
  type = string
}

variable "environment" {
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

variable "output_bucket_name" {
  type = string
}

variable "output_bucket_read_policy" {
  type = string
}

variable "output_bucket_write_policy" {
  type = string
}

variable "region" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}

variable "ecs_task_exec_arn" {
  type = string
}

variable "ecs_migration_container_name" {
  type = string
}

variable "ecs_subnet_ids" {
  type = list(string)
}

variable "ecs_security_group_id" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "ecs_task_execution_role_arn" {
  type = string
}
