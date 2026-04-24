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

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of the ECS cluster for materialized view refresh tasks"
}

variable "ecs_task_arn" {
  type        = string
  description = "ARN of the ECS task definition for materialized view refresh"
}

variable "ecs_task_role_arn" {
  type        = string
  description = "ARN of the ECS task role"
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "ARN of the ECS task execution role"
}

variable "ecs_container_name" {
  type        = string
  description = "Name of the ECS container for refresh tasks"
}

variable "ecs_security_group_id" {
  type        = string
  description = "Security group ID for ECS tasks"
}

variable "ecs_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for ECS tasks"
}
