variable "prefix" {
  type = string
}

variable "rule_name" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "task_arn" {
  type = string
}

variable "vpc_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "schedule_expression" {
  type = string
}

variable "command" {
  type = list(string)
}

variable "environment" {
  type = list(map(string))
}

variable "event_role_arn" {
  type = string
}

variable "container_name" {
  type = string
}
