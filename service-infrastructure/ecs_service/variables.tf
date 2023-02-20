variable "prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "container_port" {
  type = number
}

variable "environment_variables" {
  type = list(map(string))
}

variable "secrets" {
  type = map(string)
}

variable "parameters" {
  type = map(string)
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

variable "additional_task_role_policy_arns" {
  type        = map(string)
  default     = {}
  description = "these should not include secrets, parameters or ECS execution specific policies"
}

variable "additional_task_execution_role_policy_arns" {
  type        = map(string)
  default     = {}
  description = "these should not include secrets, parameters or ECS execution specific policies"
}

variable "aws_cloudwatch_log_group_id" {
  type = string
}
